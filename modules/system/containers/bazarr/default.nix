{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.bazarr;
  secretEnvs = [
    "BAZARR__API_KEY"
    "JELLYFIN_API_KEY"
  ];
in
{
  # postgres setup in bazarr is utterly broken, so for now, sqlite3 is the only stable option

  options.mySystemApps.bazarr = {
    enable = lib.mkEnableOption "bazarr container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/bazarr";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/bazarr/env";
    };
    videoPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing movies and tv shows.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for bazarr are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "bazarr";
    };

    virtualisation.oci-containers.containers.bazarr = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/bazarr:1.5.1@sha256:8b99750ad24d72b3105d0ffe4d14d55a01fc6685e685ef293750e81489588615";
        environment = {
          BAZARR__ANALYTICS_ENABLED = "false";

          JELLYFIN_URL = "http://jellyfin:8096";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${cfg.dataDir}/config:/config"
            "${cfg.videoPath}:/data/video"
            "${./refresh-jellyfin.sh}:/scripts/refresh-jellyfin.sh"
          ];
      };
      opts = {
        # downloading subtitles
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.bazarr = svc.mkNginxVHost {
        host = "bazarr";
        proxyPass = "http://bazarr.docker:6767";
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "bazarr";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-bazarr = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Bazarr = svc.mkHomepage "bazarr" // {
        description = "Subtitles downloader and autosync";
        widget = {
          type = "bazarr";
          url = "http://bazarr:6767";
          key = "@@BAZARR_API_KEY@@";
          fields = [
            "missingMovies"
            "missingEpisodes"
          ];
        };
      };
      secrets.BAZARR_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/BAZARR__API_KEY".path;
    };
  };
}
