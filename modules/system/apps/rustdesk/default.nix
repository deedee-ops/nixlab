{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.rustdesk;
  dataDir = "/var/lib/rustdesk";
in
{
  options.mySystemApps.rustdesk = {
    enable = lib.mkEnableOption "squid app";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    relayHost = lib.mkOption {
      type = lib.types.str;
      description = "Relay Host advertised to the clients.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for rustdesk are disabled!") ];

    users = {
      users.rustdesk = {
        isSystemUser = true;
        group = "rustdesk";
        uid = 995;
      };
      groups.rustdesk = {
        gid = 994;
      };
    };

    services = {
      rustdesk-server = lib.mkIf (!config.mySystem.recoveryMode) {
        signal.relayHosts = [ cfg.relayHost ];

        enable = true;
        openFirewall = true;

      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "rustdesk";
          paths = [ dataDir ];
        }
      );
    };

    systemd.services = lib.mkIf (!config.mySystem.recoveryMode) {
      rustdesk-signal = {
        serviceConfig = {
          WorkingDirectory = lib.mkForce dataDir;
          StateDirectory = lib.mkForce "";
        };
      };
      rustdesk-relay = {
        serviceConfig = {
          WorkingDirectory = lib.mkForce dataDir;
          StateDirectory = lib.mkForce "";
        };
      };
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              directory = dataDir;
              user = "rustdesk";
              group = "rustdesk";
              mode = "700";
            }
          ];
        };
  };
}
