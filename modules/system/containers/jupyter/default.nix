{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.jupyter;
in
{
  options.mySystemApps.jupyter = {
    enable = lib.mkEnableOption "jupyter container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing files.";
      default = "/var/lib/jupyter";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.jupyter = svc.mkContainer {
      cfg = {
        image = "quay.io/jupyter/pytorch-notebook:x86_64-2025-08-25";
        user = "1000:100";
        volumes = [
          "${cfg.dataDir}:/home/jovyan"
        ];
      }
      // lib.optionalAttrs config.myHardware.nvidia.enable {
        image = "quay.io/jupyter/pytorch-notebook:x86_64-cuda12-2025-08-25";
      };

      opts = {
        enableGPU = config.myHardware.nvidia.enable;
      };
    };

    services = {
      nginx.virtualHosts.jupyter = svc.mkNginxVHost {
        host = "jupyter";
        proxyPass = "http://jupyter.docker:8888";
      };

      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "jupyter";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-jupyter = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}"
        chown 1000:100 "${cfg.dataDir}"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };
  };
}
