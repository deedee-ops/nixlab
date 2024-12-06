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
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/qbittorrent/env";
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

    sops.secrets = {
      "${cfg.sopsSecretPrefix}/WEBUI_USERNAME" = { };
      "${cfg.sopsSecretPrefix}/WEBUI_PASSWORD" = { };
    };

    mySystemApps.gluetun.extraPorts = [ 8080 ];

    virtualisation.oci-containers.containers.qbittorrent = svc.mkContainer {
      cfg = {
        image = "ghcr.io/onedr0p/qbittorrent-beta:5.0.2@sha256:b7906b849c53fc935b2bbb43b8c041fb1a5602fd32ccec1bfaf286971b4520ee";
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

    mySystemApps.homepage = {
      services.Media.qBittorrent = svc.mkHomepage "qbittorrent" // {
        href = "https://torrents.${config.mySystem.rootDomain}";
        description = "Torrent downloader";
        widget = {
          type = "qbittorrent";
          url = "http://gluetun:8080";
          username = "@@QBITTORRENT_USERNAME@@";
          password = "@@QBITTORRENT_PASSWORD@@";
          fields = [
            "leech"
            "download"
            "seed"
            "upload"
          ];
        };
      };
      secrets = {
        QBITTORRENT_USERNAME = config.sops.secrets."${cfg.sopsSecretPrefix}/WEBUI_USERNAME".path;
        QBITTORRENT_PASSWORD = config.sops.secrets."${cfg.sopsSecretPrefix}/WEBUI_PASSWORD".path;
      };
    };
  };
}
