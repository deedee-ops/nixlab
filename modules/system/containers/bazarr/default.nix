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
        image = "ghcr.io/deedee-ops/bazarr:1.4.5@sha256:2670c12c31d885c71e87967ffc82aa27d8bb97a13bb95d4900483b6c3614ce39";
        environment = {
          BAZARR__ANALYTICS_ENABLED = "false";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${cfg.dataDir}/config:/config"
            "${cfg.videoPath}:/data/video"
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
