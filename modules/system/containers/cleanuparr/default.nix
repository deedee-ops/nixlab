{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.cleanuparr;
in
{
  options.mySystemApps.cleanuparr = {
    enable = lib.mkEnableOption "cleanuparr container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/cleanuparr";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for cleanuparr are disabled!") ];

    virtualisation.oci-containers.containers.cleanuparr = svc.mkContainer {
      cfg = {
        image = "ghcr.io/cleanuparr/cleanuparr:2.4.0@sha256:d647a5f4f85705d82e3d9204bd71fc0879e89954c9c06ae4903b6139a4088143";
        volumes = [
          "${cfg.dataDir}/config:/config"
        ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
        ];
      };

      opts = {
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.cleanuparr = svc.mkNginxVHost {
        host = "cleanuparr";
        proxyPass = "http://cleanuparr.docker:11011";
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "cleanuparr";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-cleanuparr = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 1000:1000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Cleanuparr = svc.mkHomepage "cleanuparr" // {
        icon = "cleanuperr.svg";
        description = "Downloads cleaner";
      };
    };
  };
}
