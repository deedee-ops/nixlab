{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.paperless-ngx;
  secretEnvs = [
    "HOMEPAGE_API_KEY"
    "PAPERLESS_DBPASS"
    "PAPERLESS_REDIS"
    "PAPERLESS_SECRET_KEY"
  ];
in
{
  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for paperless-ngx are disabled!") ];
    assertions = [
      {
        assertion = config.mySystemApps.tika.enable;
        message = "To use paperless-ngx, tika container needs to be enabled.";
      }
    ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "paperless-ngx";
    };

    mySystemApps = {
      postgresql.userDatabases = [
        {
          username = "paperless";
          passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/PAPERLESS_DBPASS".path;
          databases = [ "paperless" ];
        }
      ];
      redis = {
        enable = true;
        servers.paperless-ngx = 6381;
      };
    };

    virtualisation.oci-containers.containers.paperless-ngx = svc.mkContainer {
      cfg = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:2.19.6@sha256:719a4e4c4314b417646b00e58bfbfbe55e4cb59017a2dec1533e96d8deb66ec1";
        dependsOn = [
          "gotenberg"
          "tika"
        ];
        environment = {
          # s6 nonsense
          USERMAP_UID = "65000";
          USERMAP_GID = "65000";

          PAPERLESS_ALLOWED_HOSTS = "*";
          PAPERLESS_CONSUMER_POLLING = "0"; # use ionotify
          PAPERLESS_CONSUMER_RECURSIVE = "true";
          PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = "true";
          PAPERLESS_CONSUMPTION_DIR = "/data/consume";
          PAPERLESS_DATA_DIR = "/config";

          # DMY will be parsed incorrectly for YYYY-MM-DD dates, while YMD is parsed correctly for DD-MM-YYYY
          # given, that proper dateparser locale is set
          PAPERLESS_DATE_ORDER = "YMD";
          PAPERLESS_DATE_PARSER_LANGUAGES = "pl+en";

          PAPERLESS_DBHOST = "host.docker.internal";
          PAPERLESS_DBNAME = "paperless";
          PAPERLESS_DBPORT = "5432";
          PAPERLESS_DBSSLMODE = "prefer";
          PAPERLESS_DBUSER = "paperless";
          PAPERLESS_ENABLE_HTTP_REMOTE_USER = "true";
          PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
          PAPERLESS_MEDIA_ROOT = "/data/media";
          PAPERLESS_OCR_LANGUAGE = "eng+pol";
          PAPERLESS_OCR_LANGUAGES = "pol";
          PAPERLESS_OCR_USER_ARGS = "{\"invalidate_digital_signatures\": true}";
          PAPERLESS_PORT = "8000";
          PAPERLESS_SUPERVISORD_WORKING_DIR = "/tmp";
          PAPERLESS_TASK_WORKERS = "2";
          PAPERLESS_TIKA_ENABLED = "1";
          PAPERLESS_TIKA_ENDPOINT = "http://tika:9998";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://gotenberg:3000";
          PAPERLESS_TIME_ZONE = config.mySystem.time.timeZone;
          PAPERLESS_URL = "https://paperless.${config.mySystem.rootDomain}";
        }
        // svc.mkContainerSecretsEnv { inherit secretEnvs; }
        // lib.optionalAttrs config.mySystem.networking.completelyDisableIPV6 {
          PAPERLESS_BIND_ADDR = "0.0.0.0";
        };
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
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--cap-add=CAP_FSETID"
          "--cap-add=CAP_KILL"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
          "--cap-add=CAP_SYS_CHROOT"
        ];
      };
      opts = {
        # download OCR package
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.paperless-ngx = svc.mkNginxVHost {
        host = "paperless";
        proxyPass = "http://paperless-ngx.docker:8000";
        autheliaIgnorePaths = [ "/api" ];
        customCSP = ''
          default-src 'self' 'unsafe-inline' data: blob: wss:;
          img-src 'self' data: *.${config.mySystem.rootDomain};
          manifest-src 'self' *.${config.mySystem.rootDomain};
          object-src 'self';
        '';
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "paperless" ]; };
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
        chown 65000:65000 "${cfg.dataDir}/config" "${cfg.dataDir}/data"
        chmod 777 "${cfg.dataDir}/data/consume"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps = {
      syncthing.extraPaths = {
        "paperless-ngx/consume" = {
          dest = "${cfg.dataDir}/data/consume";
        };
        "paperless-ngx/documents" = {
          dest = "${cfg.dataDir}/data/media/documents/archive";
          readOnly = true;
        };
      };

      homepage = {
        services.Apps.Paperless-NGX = svc.mkHomepage "paperless-ngx" // {
          href = "https://paperless.${config.mySystem.rootDomain}";
          description = "Documents OCR and archive";
          widget = {
            type = "paperlessngx";
            url = "http://paperless-ngx:8000";
            key = "@@PAPERLESSNGX_API_KEY@@";
            fields = [
              "inbox"
              "total"
            ];
          };
        };
        secrets.PAPERLESSNGX_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/HOMEPAGE_API_KEY".path;
      };
    };
  };
}
