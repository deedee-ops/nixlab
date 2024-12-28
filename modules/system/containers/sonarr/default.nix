{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.sonarr;
  secretEnvs = [
    "SONARR__AUTH__APIKEY"
    "SONARR__POSTGRES__PASSWORD"
  ];
in
{
  options.mySystemApps.sonarr = {
    enable = lib.mkEnableOption "sonarr container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/sonarr";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/sonarr/env";
    };
    mediaPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing media.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for sonarr are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "sonarr";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "sonarr";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/SONARR__POSTGRES__PASSWORD".path;
        databases = [ "sonarr" ];
      }
    ];

    virtualisation.oci-containers.containers.sonarr = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/sonarr-devel:4.0.11.2804@sha256:019194ef020f1704c761afed952214f96d001347575165445456a920a001975d";
        environment = {
          SONARR__APP__INSTANCENAME = "Sonarr";
          SONARR__APP__THEME = "dark";
          SONARR__AUTH__METHOD = "External";
          SONARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
          SONARR__LOG__ANALYTICSENABLED = "False";
          SONARR__LOG__DBENABLED = "False";
          SONARR__LOG__LEVEL = "info";
          SONARR__POSTGRES__HOST = "host.docker.internal";
          SONARR__POSTGRES__MAINDB = "sonarr";
          SONARR__POSTGRES__USER = "sonarr";
          SONARR__UPDATE__BRANCH = "develop";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${cfg.dataDir}/config:/config"
            "${cfg.mediaPath}:/data"
            "${./refresh-series.sh}:/scripts/refresh-series.sh"
          ];
      };
      opts = {
        # downloading metadata
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.sonarr = svc.mkNginxVHost {
        host = "sonarr";
        proxyPass = "http://sonarr.docker:8989";
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "sonarr" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "sonarr";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-sonarr = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Sonarr = svc.mkHomepage "sonarr" // {
        description = "TV Shows management";
        widget = {
          type = "sonarr";
          url = "http://sonarr:8989";
          key = "@@SONARR_API_KEY@@";
          fields = [
            "wanted"
            "series"
            "queued"
          ];
        };
      };
      secrets.SONARR_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/SONARR__AUTH__APIKEY".path;
    };
  };
}
