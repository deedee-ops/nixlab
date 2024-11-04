{
  config,
  lib,
  pkgs,
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

    systemd.services.rustdesk-relay = {
      serviceConfig = {
        ReadWritePaths = "${dataDir}";
      };
      path = [
        pkgs.diffutils
        pkgs.procps
      ];
      postStart = lib.mkAfter ''
        while [ ! -e /var/lib/rustdesk/id_ed25519 ]; do sleep 0.5; done
        chown -R rustdesk:rustdesk "${dataDir}"
        if ! diff "${dataDir}/id_ed25519" /var/lib/rustdesk/id_ed25519; then
          [ -e "${dataDir}/id_ed25519" ] && cp "${dataDir}/id_ed25519" /var/lib/rustdesk
          [ -e "${dataDir}/id_ed25519.pub" ] && cp "${dataDir}/id_ed25519.pub" /var/lib/rustdesk
          pkill -f 'rustdesk.*hbbr'
        fi
        cp -r /var/lib/rustdesk/* "${dataDir}"
      '';
      preStop = lib.mkAfter ''
        cp -r /var/lib/rustdesk/* "${dataDir}"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ dataDir ]; };
  };
}
