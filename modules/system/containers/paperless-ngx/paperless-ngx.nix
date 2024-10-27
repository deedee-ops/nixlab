{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.paperless-ngx;
  secretEnvs = [
    "PAPERLESS_DBPASS"
    "PAPERLESS_REDIS"
    "PAPERLESS_SECRET_KEY"
  ];
in
{
  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for paperless-ngx are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "paperless-ngx";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "paperless";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/PAPERLESS_DBPASS".path;
        databases = [ "paperless" ];
      }
    ];

    virtualisation.oci-containers.containers.paperless-ngx = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/paperless-ngx:2.12.1@sha256:0e6487675bf7a9008af5f4d67731e753e305d3ee28c9ec0b637512f6a578f371";
        dependsOn = [
          "gotenberg"
          "tika"
        ];
        environment = {
          PAPERLESS_ALLOWED_HOSTS = "*";
          PAPERLESS_CONSUMER_POLLING = "0"; # use ionotify
          PAPERLESS_CONSUMER_RECURSIVE = "true";
          PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = "true";
          PAPERLESS_DBHOST = "host.docker.internal";
          PAPERLESS_DBNAME = "paperless";
          PAPERLESS_DBPORT = "5432";
          PAPERLESS_DBSSLMODE = "prefer";
          PAPERLESS_DBUSER = "paperless";
          PAPERLESS_ENABLE_HTTP_REMOTE_USER = "true";
          PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
          PAPERLESS_OCR_LANGUAGE = "eng+pol";
          PAPERLESS_OCR_USER_ARGS = "{\"invalidate_digital_signatures\" = true}";
          PAPERLESS_PORT = "8000";
          PAPERLESS_TASK_WORKERS = "2";
          PAPERLESS_TIKA_ENABLED = "1";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://gotenberg:3000";
          PAPERLESS_TIKA_ENDPOINT = "http://tika:9998";
          PAPERLESS_TIME_ZONE = config.mySystem.time.timeZone;
          PAPERLESS_URL = "https://paperless.${config.mySystem.rootDomain}";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${cfg.dataDir}/config:/config"
            "${cfg.dataDir}/data/consume:/data/consume"
            "${cfg.dataDir}/data/media:/data/media"
          ];
      };
    };

    services = {
      nginx.virtualHosts.paperless-ngx = svc.mkNginxVHost {
        host = "paperless";
        proxyPass = "http://paperless-ngx.docker:8000";
        autheliaIgnorePaths = [ "/api" ];
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "paperless-ngx" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "paperless-ngx";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-paperless-ngx = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config" "${cfg.dataDir}/data/consume" "${cfg.dataDir}/data/media"
        chown -R 65000:65000 "${cfg.dataDir}/config" "${cfg.dataDir}/data"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.syncthing.extraPaths = {
      "paperless-ngx/consume" = {
        dest = "${cfg.dataDir}/data/consume";
      };
      "paperless-ngx/documents" = {
        dest = "${cfg.dataDir}/data/media/documents/archive";
        readOnly = true;
      };
    };
  };
}
