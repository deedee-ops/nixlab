{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.pinchflat;
in
{
  options.mySystemApps.pinchflat = {
    enable = lib.mkEnableOption "pinchflat container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/pinchflat";
    };
    downloadsPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing downloaded videos.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for pinchflat are disabled!") ];

    virtualisation.oci-containers.containers.pinchflat = svc.mkContainer {
      cfg = {
        image = "ghcr.io/kieraneglin/pinchflat:v2025.1.27@sha256:01e52e1f1025aea789acd83dd05735d6875d61539f8283a7b4f83e8f470a0627";
        user = "65000:65000";
        environment = {
          TZ_DATA_DIR = "/tmp/elixir_tz_data";
        };
        volumes = [
          "${cfg.dataDir}/config:/config"
          "${cfg.downloadsPath}:/downloads"
        ];
        extraOptions = [
          "--device=/dev/dri"
          "--mount"
          "type=tmpfs,destination=/etc/yt-dlp,tmpfs-mode=1777"
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
      opts = {
        # for fetching youtube videos
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.pinchflat = svc.mkNginxVHost {
        host = "pinchflat";
        proxyPass = "http://pinchflat.docker:8945";
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "pinchflat";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-pinchflat = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Pinchflat = svc.mkHomepage "pinchflat" // {
        description = "YouTube downloader";
      };
    };
  };
}
