{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.homepage;
  wrapSet =
    set: builtins.map (key: { "${key}" = builtins.getAttr key set; }) (builtins.attrNames set);

  settings = (pkgs.formats.yaml { }).generate "settings.yaml" cfg.settings;
  services = (pkgs.formats.yaml { }).generate "services.yaml" (
    wrapSet (builtins.mapAttrs (_name: wrapSet) cfg.services)
  );
  widgets = ./widgets.yaml;
in
{
  options.mySystemApps.homepage = {
    enable = lib.mkEnableOption "homepage container";
    settings = lib.mkOption {
      type = lib.types.attrs;
      description = "Base settings for homepage";
      default = {
        language = "en";
        theme = "dark";
        color = "zinc";
        target = "_self";
        headerStyle = "boxed";
        statusStyle = "dot";
        hideVersion = true;
        disableCollapse = true;
        useEqualHeights = true;
        base = "https://www.${config.mySystem.rootDomain}";
        layout = {
          Apps = {
            style = "row";
            columns = 4;
          };
          Media = {
            style = "row";
            columns = 4;
          };
        };
      };
    };
    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.attrs);
      description = "Services sorted by group/name config.";
      default = { };
      example = {
        "Media" = {
          "jellyfin" = {
            href = "https://jellyfin.example.com";
          };
        };
      };
    };
    secrets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Key-value pair of secret alias and file containing the value. These will be replaced in services.yaml file.";
      example = lib.options.literalExpression ''
        { MY_SECRET_VAR = config.sops.secrets."MY_SECRET_VAR".path }
      '';
      default = { };
    };
    greeting = lib.mkOption {
      type = lib.types.str;
      description = "Title displayed in upper left corner.";
      default = "homelab";
    };
    disks = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Key-value pair of disks to be displayed in metrics, where key is the label, and value is mountpath.";
      example = {
        SYSTEM = "/";
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    mySystemApps.docker.startDockerSockProxy = true;

    virtualisation.oci-containers.containers.homepage = svc.mkContainer {
      cfg = {
        dependsOn = [ "socket-proxy" ];
        user = "1000:1000";
        image = "ghcr.io/gethomepage/homepage:v0.9.11@sha256:d41dca72f3a68d2c675eb232a448104af200096f05e2610ffbfdb16bc7f71410";
        environment = {
          LOG_LEVEL = "debug";
        };
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/app/config,tmpfs-mode=1777"
        ];
        volumes = [
          "${./bookmarks.yaml}:/app/config/bookmarks.yaml:ro"
          "${./custom.css}:/app/config/custom.css:ro"
          "${settings}:/app/config/settings.yaml:ro"
          "${./docker.yaml}:/app/config/docker.yaml:ro"
          "/run/homepage/services.yaml:/app/config/services.yaml:ro"
          "/run/homepage/widgets.yaml:/app/config/widgets.yaml:ro"
        ];
      };
      opts = {
        disableReadOnly = true;
      };
    };

    services = {
      nginx.virtualHosts.homepage = svc.mkNginxVHost {
        host = "www";
        proxyPass = "http://homepage.docker:3000";
        customCSP = ''
          default-src 'self' 'unsafe-inline' data: blob: wss:;
          connect-src 'self' https://api.github.com *.${config.mySystem.rootDomain};
          manifest-src 'self' *.${config.mySystem.rootDomain};
          img-src 'self' https://cdn.jsdelivr.net; object-src 'none';
        '';
      };
    };

    systemd.services.docker-homepage = {
      preStart = lib.mkAfter (
        ''
          mkdir -p /run/homepage
          cp ${services} /run/homepage/services.yaml
          cp ${widgets} /run/homepage/widgets.yaml
          sed -i"" 's,@@GREETING@@,${cfg.greeting},g' /run/homepage/widgets.yaml
        ''
        + (
          if config.mySystemApps.whoogle.enable then
            ''
              sed -i"" 's,@@SEARCH_PROVIDER@@,custom,g' /run/homepage/widgets.yaml
              sed -i"" 's,@@SEARCH_URL@@,https://whoogle.${config.mySystem.rootDomain}/search?q=,g' /run/homepage/widgets.yaml
            ''
          else
            ''
              sed -i"" 's,@@SEARCH_PROVIDER@@,duckduckgo,g' /run/homepage/widgets.yaml
              sed -i"" 's,@@SEARCH_URL@@,,g' /run/homepage/widgets.yaml
            ''
        )
        + ''
          sed -i"" 's#@@DISKS_CONFIG@@#${
            builtins.concatStringsSep "" (
              builtins.map (
                label:
                "\\n- { resources: { label: ${label}, expanded: true, disk: [\"${builtins.getAttr label cfg.disks}\"] } }\\n"
              ) (builtins.attrNames cfg.disks)
            )
          }#g' /run/homepage/widgets.yaml
          chown 1000:1000 /run/homepage /run/homepage/services.yaml /run/homepage/widgets.yaml
        ''
        + (builtins.concatStringsSep "\n" (
          builtins.map (
            name:
            "sed -i'' \"s,@@${name}@@,$(cat ${builtins.getAttr name cfg.secrets}),g\" /run/homepage/services.yaml"
          ) (builtins.attrNames cfg.secrets)
        ))
      );
    };
  };
}
