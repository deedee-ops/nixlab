{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.qbittorrent;
in
{
  options.mySystemApps.qbittorrent = {
    enable = lib.mkEnableOption "qbittorrent container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/qbittorrent";
    };
    downloadsPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing downloads.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for qbittorrent are disabled!") ];
    assertions = [
      {
        assertion = config.mySystemApps.gluetun.enable;
        message = "To use qbittorrent, gluetun container needs to be enabled.";
      }
    ];

    mySystemApps.gluetun.extraPorts = [ 8080 ];

    virtualisation.oci-containers.containers.qbittorrent = svc.mkContainer {
      cfg = {
        image = "ghcr.io/onedr0p/qbittorrent-beta:5.0.1@sha256:274b6a99c702fcb6ae881ec6972e1cdbf1ac1b0f0a09711c4a3de9944cea4f86";
        user = "65000:65000";
        environment = {
          QBT_TORRENTING_PORT = "${builtins.toString config.mySystemApps.gluetun.forwardedPort}";
        };
        volumes = [
          "${cfg.dataDir}/config:/config"
          "${cfg.downloadsPath}:/data/torrents"
        ];
      };
      opts = {
        routeThroughVPN = true;
      };
    };

    services = {
      nginx.virtualHosts.qbittorrent = svc.mkNginxVHost {
        host = "torrents";
        proxyPass = "http://gluetun.docker:8080";
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "qbittorrent";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-qbittorrent = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };
  };
}
