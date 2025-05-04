{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.matchbox;
in
{
  options.mySystemApps.matchbox = {
    enable = lib.mkEnableOption "matchbox container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    exposeGRPC = lib.mkEnableOption "gRPC API";
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing files.";
      default = "/var/lib/matchbox";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.matchbox = svc.mkContainer {
      cfg = {
        image = "quay.io/poseidon/matchbox:v0.11.0@sha256:06bcdae85335fd00e8277b007b55cfb49d96a0114628c0f70db2b92b079d246a";
        user = "65000:65000";
        cmd =
          [
            "-address=0.0.0.0:8080"
          ]
          ++ lib.optionals cfg.exposeGRPC [
            "-rpc-address=0.0.0.0:8081"
          ];
        volumes = [
          "${cfg.dataDir}/config:/etc/matchbox:Z"
          "${cfg.dataDir}/data:/var/lib/matchbox:Z"
        ];
      };
    };

    services = {
      nginx.virtualHosts = {
        matchbox = svc.mkNginxVHost {
          host = "matchbox";
          proxyPass = "http://matchbox.docker:8080";
          useAuthelia = false;
        };

        matchbox-rpc = lib.mkIf cfg.exposeGRPC (
          svc.mkNginxVHost {
            host = "matchbox-rpc";
            proxyPass = "http://matchbox.docker:8081";
            useAuthelia = false;
          }
        );
      };

      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "matchbox";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-matchbox = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config" "${cfg.dataDir}/data/assets"
        chown 65000:65000 "${cfg.dataDir}/config" "${cfg.dataDir}/data" "${cfg.dataDir}/data/assets"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              user = config.users.users.abc.name;
              group = config.users.groups.abc.name;
              directory = cfg.dataDir;
              mode = "755";
            }
          ];
        };
  };
}
