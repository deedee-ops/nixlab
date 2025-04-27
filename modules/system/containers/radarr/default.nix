{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.radarr;
  secretEnvs = [
    "RADARR__AUTH__APIKEY"
    "RADARR__POSTGRES__PASSWORD"
  ];
in
{
  options.mySystemApps.radarr = {
    enable = lib.mkEnableOption "radarr container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/radarr";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/radarr/env";
    };
    mediaPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing media.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for radarr are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "radarr";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "radarr";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/RADARR__POSTGRES__PASSWORD".path;
        databases = [ "radarr" ];
      }
    ];

    virtualisation.oci-containers.containers.radarr = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/radarr-devel:5.23.0.9907@sha256:9084a3ec5cdbd53efd67d4b98b8f14bb9f8dd088455eb08d1d250bf9127b14be";
        environment = {
          RADARR__APP__INSTANCENAME = "Radarr";
          RADARR__APP__THEME = "dark";
          RADARR__AUTH__METHOD = "External";
          RADARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
          RADARR__LOG__ANALYTICSENABLED = "False";
          RADARR__LOG__DBENABLED = "False";
          RADARR__LOG__LEVEL = "info";
          RADARR__POSTGRES__HOST = "host.docker.internal";
          RADARR__POSTGRES__MAINDB = "radarr";
          RADARR__POSTGRES__USER = "radarr";
          RADARR__UPDATE__BRANCH = "develop";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${cfg.dataDir}/config:/config"
            "${cfg.mediaPath}:/data"
          ];
      };
      opts = {
        # downloading metadata
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.radarr = svc.mkNginxVHost {
        host = "radarr";
        proxyPass = "http://radarr.docker:7878";
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "radarr" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "radarr";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-radarr = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Radarr = svc.mkHomepage "radarr" // {
        description = "Movies management";
        widget = {
          type = "radarr";
          url = "http://radarr:7878";
          key = "@@RADARR_API_KEY@@";
          fields = [
            "wanted"
            "movies"
            "queued"
            "missing"
          ];
        };
      };
      secrets.RADARR_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/RADARR__AUTH__APIKEY".path;
    };
  };
}
