{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.wakapi;
  secretEnvs = [
    "WAKAPI_PASSWORD_SALT"
    "WAKAPI_DB_PASSWORD"
  ];
in
{
  options.mySystemApps.wakapi = {
    enable = lib.mkEnableOption "wakapi container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/wakapi/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for wakapi are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "wakapi";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "wakapi";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/WAKAPI_DB_PASSWORD".path;
        databases = [ "wakapi" ];
      }
    ];

    virtualisation.oci-containers.containers.wakapi = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/wakapi:2.12.3@sha256:ca51b3abef79aede7218b48d2c80d350e044c566208346eb273b8ded06f8cbd2";
        environment = {
          ENVIRONMENT = "prod";
          WAKAPI_LEADERBOARD_ENABLED = "false";
          WAKAPI_IMPORT_ENABLED = "true";
          WAKAPI_SUPPORT_CONTACT = config.mySystem.notificationSender;
          WAKAPI_DATA_RETENTION_MONTHS = "-1";
          WAKAPI_MAX_INACTIVE_MONTHS = "-1";
          WAKAPI_PORT = "3000";
          WAKAPI_LISTEN_IPV4 = "0.0.0.0";
          WAKAPI_LISTEN_IPV6 = "-";
          WAKAPI_LISTEN_SOCKET = "-";
          WAKAPI_BASE_PATH = "/";
          WAKAPI_PUBLIC_URL = "https://wakapi.${config.mySystem.rootDomain}";
          WAKAPI_ALLOW_SIGNUP = "false";
          WAKAPI_INVITE_CODES = "false";
          WAKAPI_DISABLE_FRONTPAGE = "true";
          WAKAPI_EXPOSE_METRICS = "false";
          WAKAPI_TRUSTED_HEADER_AUTH = "true";
          WAKAPI_TRUSTED_HEADER_AUTH_KEY = "Remote-User";
          WAKAPI_TRUST_REVERSE_PROXY_IPS = "172.16.0.0/12";
          # ---;
          WAKAPI_DB_TYPE = "postgres";
          WAKAPI_DB_PORT = "5432";
          WAKAPI_DB_USER = "wakapi";
          WAKAPI_DB_HOST = "host.docker.internal";
          WAKAPI_DB_NAME = "wakapi";
          WAKAPI_MAIL_ENABLED = "true";
          WAKAPI_MAIL_SMTP_HOST = "maddy";
          WAKAPI_MAIL_SMTP_PORT = "25";
          WAKAPI_MAIL_SMTP_TLS = "false";
          WAKAPI_SENTRY_TRACING = "false";
          WAKAPI_QUICK_START = "false";
          WAKAPI_ENABLE_PPROF = "false";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes = svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
        };
      };
    };

    services = {
      nginx.virtualHosts.wakapi = svc.mkNginxVHost {
        host = "wakapi";
        proxyPass = "http://wakapi.docker:3000";
        autheliaIgnorePaths = [ "/api" ];
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "wakapi" ]; };
    };

    mySystemApps.homepage = {
      services.Apps.Wakapi = svc.mkHomepage "wakapi" // {
        description = "Coding time tracker";
      };
    };
  };
}
