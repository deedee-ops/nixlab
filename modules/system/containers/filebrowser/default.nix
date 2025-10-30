{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.filebrowser;

  configYaml = pkgs.writeText "config.yaml" (
    builtins.toJSON {
      server = {
        port = 3000;
        baseURL = "/";
        externalUrl = "https://${cfg.subdomain}.${config.mySystem.rootDomain}";
        sources = builtins.attrValues cfg.sources;
      };
      auth = {
        methods = {
          proxy = {
            enabled = config.mySystemApps.authelia.enable;
            createUser = false;
            header = "Remote-User";
          };
        };
        adminUsername = "admin";
      };
      frontend = {
        externalLinks = [ ];
      };
      userDefaults = {
        darkMode = true;
        viewMode = "list";
        singleClick = true;
        showHidden = true;
        quickDownload = true;
        preview = {
          image = true;
          popup = true;
        };
      };
    }
  );
in
{
  options.mySystemApps.filebrowser = {
    enable = lib.mkEnableOption "filebrowser container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/filebrowser";
    };
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing filebrowser envs.";
      default = "system/apps/filebrowser/envfile";
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "Subdomain for ${config.mySystem.rootDomain}.";
      default = "files";
    };
    sources = lib.mkOption {
      type = lib.types.attrs;
      description = ''
        List of directories to be available in filebrowser. Key is the path on host server, the value must match `sources`
        section of filebrowser config: <https://github.com/gtsteffaniak/filebrowser/wiki/Full-Config-Example#full-config-example>
      '';
      example = {
        "/tank/media" = {
          path = "/media";
          name = "media";
          config.disableIndexing = true;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.filebrowser = svc.mkContainer {
      cfg = {
        image = "ghcr.io/gtsteffaniak/filebrowser:1.0.0-beta@sha256:535c8ab7f639deff162392eba0be29c92ff5e236ffc4a577b1f7b065e10313db";
        user = "65000:65000";
        environment = {
          FILEBROWSER_CONFIG = "/config/config.yaml";
        };
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
        volumes = [
          "${configYaml}:/config/config.yaml:ro"
          "${cfg.dataDir}:/home/filebrowser/data"
        ]
        ++ (builtins.map (name: "${name}:${(builtins.getAttr name cfg.sources).path}") (
          builtins.attrNames cfg.sources
        ));
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/home/filebrowser/tmp,tmpfs-mode=1777"
        ];
      };
    };

    services = {
      nginx.virtualHosts.filebrowser = svc.mkNginxVHost {
        host = cfg.subdomain;
        proxyPass = "http://filebrowser.docker:3000";
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "filebrowser";
          paths = [ cfg.dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              user = config.users.users.abc.name;
              group = config.users.groups.abc.name;
              directory = cfg.dataDir;
              mode = "750";
            }
          ];
        };

    mySystemApps.homepage = {
      services.Media.Filebrowser = svc.mkHomepage "filebrowser" // {
        href = "https://${cfg.subdomain}.${config.mySystem.rootDomain}";
        description = "NAS filebrowser";
      };
    };
  };
}
