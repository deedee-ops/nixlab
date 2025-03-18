{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.pinchflat;
  secretEnvs = lib.optionals config.mySystemApps.jellyfin.enable [
    "JELLYFIN_API_KEY"
  ];
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
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/pinchflat/env";
    };
    downloadsPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing downloaded videos.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for pinchflat are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "pinchflat";
    };

    virtualisation.oci-containers.containers.pinchflat = svc.mkContainer {
      cfg = {
        image = "ghcr.io/kieraneglin/pinchflat:v2025.3.17@sha256:1c5f79531c00529f525d16d926179ef260b9c0e27119f8c95867a62aba9267f8";
        user = "65000:65000";
        environment =
          {
            LOG_LEVEL = "info";
            TZ_DATA_DIR = "/tmp/elixir_tz_data";
          }
          // lib.optionalAttrs config.mySystemApps.jellyfin.enable {
            JELLYFIN_URL = "http://jellyfin:8096";
          };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
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
      preStart = lib.mkAfter (
        ''
          mkdir -p "${cfg.dataDir}/config/extras/user-scripts"
          chown 65000:65000 "${cfg.dataDir}/config" "${cfg.dataDir}/config/extras" "${cfg.dataDir}/config/extras/user-scripts"
        ''
        + (lib.optionalString config.mySystemApps.jellyfin.enable ''
          cp "${./refresh-jellyfin.sh}" "${cfg.dataDir}/config/extras/user-scripts/lifecycle"
          chown 65000:65000 "${cfg.dataDir}/config/extras/user-scripts/lifecycle"
        '')
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Pinchflat = svc.mkHomepage "pinchflat" // {
        icon = "pinchflat.png";
        description = "YouTube downloader";
      };
    };
  };
}
