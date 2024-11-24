{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.vikunja;
  secretEnvs = [
    "VIKUNJA_API_KEY"
    "VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHELIA_CLIENTSECRET"
    "VIKUNJA_DATABASE_PASSWORD"
    "VIKUNJA_SERVICE_JWTSECRET"
  ];
in
{
  options.mySystemApps.vikunja = {
    enable = lib.mkEnableOption "vikunja container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/vikunja";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/vikunja/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for vikunja are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "vikunja";
    };

    mySystemApps = {
      postgresql.userDatabases = [
        {
          username = "vikunja";
          passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/VIKUNJA_DATABASE_PASSWORD".path;
          databases = [ "vikunja" ];
        }
      ];

      authelia.oidcClients = [
        {
          client_id = "vikunja";
          client_name = "vikunja";
          client_secret = "$pbkdf2-sha512$310000$Pu0EbGsNGP9OuYIhuDQhKg$bhC3zw1gzOYZHRA6T4WDN79am79RjXyyJO.TnK5Xq39j9kCuiOdjmJXJA13K4Tp3Sol2jzgVTWdzoM1dCNX0eg"; # unencrypted version in SOPS
          consent_mode = "implicit";
          public = false;
          authorization_policy = "two_factor";
          redirect_uris = [
            "https://vikunja.${config.mySystem.rootDomain}/auth/openid/authelia"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

    };

    virtualisation.oci-containers.containers.vikunja = svc.mkContainer {
      cfg = {
        image = "vikunja/vikunja:unstable"; # @todo wait for 0.25.x which supports *_FILE envs
        user = "65000:65000";
        environment = {
          VIKUNJA_AUTH_OPENID_ENABLED = "true";
          VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHELIA_AUTHURL = "https://authelia.${config.mySystem.rootDomain}";
          VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHELIA_CLIENTID = "vikunja";
          VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHELIA_NAME = "Authelia";
          VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHELIA_SCOPE = "openid profile email";
          VIKUNJA_AUTOTLS_ENABLED = "false";
          VIKUNJA_BACKGROUNDS_PROVIDERS_UNSPLASH_ENABLED = "false";
          VIKUNJA_BACKGROUNDS_PROVIDERS_UPLOAD_ENABLED = "true";
          VIKUNJA_DATABASE_DATABASE = "vikunja";
          VIKUNJA_DATABASE_HOST = "host.docker.internal:5432";
          VIKUNJA_DATABASE_TYPE = "postgres";
          VIKUNJA_DATABASE_USER = "vikunja";
          VIKUNJA_DEFAULTSETTINGS_EMAIL_REMINDERS_ENABLED = "true";
          VIKUNJA_DEFAULTSETTINGS_OVERDUE_TASKS_REMINDERS_ENABLED = "true";
          VIKUNJA_DEFAULTSETTINGS_TIMEZONE = config.mySystem.time.timeZone;
          VIKUNJA_DEFAULTSETTINGS_WEEK_START = "1"; # Monday
          VIKUNJA_KEYVALUE_TYPE = "redis";
          VIKUNJA_MAILER_ENABLED = "true";
          VIKUNJA_MAILER_FROMEMAIL = config.mySystem.notificationSender;
          VIKUNJA_MAILER_HOST = "maddy";
          VIKUNJA_MAILER_PASSWORD = "";
          VIKUNJA_MAILER_PORT = "25";
          VIKUNJA_MAILER_SKIPTLSVERIFY = "true";
          VIKUNJA_MAILER_USERNAME = "";
          VIKUNJA_METRICS_ENABLED = "false";
          VIKUNJA_MIGRATION_MICROSOFTTODO_ENABLE = "false";
          VIKUNJA_MIGRATION_TODOIST_ENABLE = "false";
          VIKUNJA_MIGRATION_TRELLO_ENABLE = "false";
          VIKUNJA_REDIS_ENABLED = "true";
          VIKUNJA_REDIS_HOST = "host.docker.internal:6379";
          VIKUNJA_REDIS_PASSWORD_FILE = "/secrets/VIKUNJA_REDIS_PASSWORD";
          VIKUNJA_SENTRY_ENABLED = "false";
          VIKUNJA_SENTRY_FRONTENDENABLED = "false";
          VIKUNJA_SERVICE_DEMOMODE = "false";
          VIKUNJA_SERVICE_ENABLECALDAV = "true";
          VIKUNJA_SERVICE_ENABLEEMAILREMINDERS = "true";
          VIKUNJA_SERVICE_ENABLEPUBLICTEAMS = "false";
          VIKUNJA_SERVICE_ENABLEREGISTRATION = "false";
          VIKUNJA_SERVICE_ENABLETASKATTACHMENTS = "true";
          VIKUNJA_SERVICE_ENABLETASKCOMMENTS = "true";
          VIKUNJA_SERVICE_ENABLETOTP = "false";
          VIKUNJA_SERVICE_ENABLEUSERDELETION = "false";
          VIKUNJA_SERVICE_PUBLICURL = "https://vikunja.${config.mySystem.rootDomain}";
          VIKUNJA_SERVICE_TIMEZONE = config.mySystem.time.timeZone;
          VIKUNJA_WEBHOOKS_ENABLED = "false";
        } // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${./config.yaml}:/app/vikunja/config.yaml"
            "${cfg.dataDir}/files:/app/vikunja/files"
            "${
              config.sops.secrets."${config.mySystemApps.redis.passFileSopsSecret}".path
            }:/secrets/VIKUNJA_REDIS_PASSWORD:ro"
          ];
        extraOptions = [
          "--add-host=authelia.${config.mySystem.rootDomain}:${config.mySystemApps.docker.network.private.hostIP}"
        ];
      };
    };

    services = {
      nginx.virtualHosts.vikunja = svc.mkNginxVHost {
        host = "vikunja";
        proxyPass = "http://vikunja.docker:3456";
        autheliaIgnorePaths = [
          "/dav"
          "/.well-known"
        ];
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "vikunja" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "vikunja";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-vikunja = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/files"
        chown 65000:65000 "${cfg.dataDir}/files"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.vikunja = svc.mkHomepage "vikunja" // {
        description = "Task manager";
        widget = {
          type = "vikunja";
          url = "http://vikunja:3456";
          key = "@@VIKUNJA_API_KEY@@";
          fields = [
            "tasksOverdue"
            "tasks7d"
            "projects"
            "tasksInProgress"
          ];
        };
      };
      secrets.VIKUNJA_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/VIKUNJA_API_KEY".path;
    };
  };
}
