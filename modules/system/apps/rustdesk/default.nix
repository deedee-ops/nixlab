{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.rustdesk;
  dataDir = "/var/lib/rustdesk.backup";
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

    services = {
      rustdesk-server = {
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

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ dataDir ]; };
  };
}
