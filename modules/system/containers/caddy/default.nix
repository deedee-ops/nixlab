{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.caddy;
in
{
  options.mySystemApps.caddy = {
    enable = lib.mkEnableOption "caddy container";
    dependsOn = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of containers caddy will depend on.";
      default = [ ];
    };
    vhosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      description = "Caddy configurations per vhost";
      default = { };
      example = {
        "test.example.com" = ''
          log
          root * /var/www/test
        '';
      };
    };
    mounts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of extra mounts in caddy container, in docker format.";
      default = [ ];
      example = [
        "/my/host/path:/var/www/test"
      ];
    };
  };

  config =
    let
      caddyfile = pkgs.writeText "Caddyfile" (
        ''
          {
            log {
              level info
              output stderr
              format console
            }
            http_port 8080
            https_port 8443
            servers {
              trusted_proxies static 172.16.0.0/12
              trusted_proxies_strict
            }
          }
        ''
        + (builtins.concatStringsSep "\n" (
          builtins.map (vhost: ''
            ${vhost}:8080 {
            ${builtins.getAttr vhost cfg.vhosts}
            }
          '') (builtins.attrNames cfg.vhosts)
        ))
      );
    in
    lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers.caddy = svc.mkContainer {
        cfg = {
          inherit (cfg) dependsOn;

          image = "public.ecr.aws/docker/library/caddy:2.9.1@sha256:7f0336b2c9930a6d84529303563d65880072938c538a9a7713dbffa0f876c951";
          volumes = [ "${caddyfile}:/config/Caddyfile" ] ++ cfg.mounts;
          cmd = [
            "caddy"
            "run"
            "--config"
            "/config/Caddyfile"
          ];
          extraOptions = [
            "--cap-add=CAP_NET_BIND_SERVICE"
            "--mount"
            "type=tmpfs,destination=/config/caddy,tmpfs-mode=1777"
            "--mount"
            "type=tmpfs,destination=/data/caddy,tmpfs-mode=1777"
          ];
        };
      };
    };
}
