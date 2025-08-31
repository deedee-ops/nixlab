{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.outline;
  secretEnvs = [
    "DATABASE_URL"
    "OIDC_CLIENT_SECRET"
    "OUTLINE_DB_PASSWORD"
    "REDIS_URL"
    "SECRET_KEY"
    "UTILS_SECRET"
  ];
in
{
  options.mySystemApps.outline = {
    enable = lib.mkEnableOption "outline container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/outline";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/outline/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for outline are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "outline";
    };

    mySystemApps = {
      authelia.oidcClients = [
        {
          client_id = "outline";
          client_name = "outline";
          client_secret = "$pbkdf2-sha512$310000$0GLChtY56K3phnc1oEL.0w$YTZ0C8iMbM/acCu0gLzciwxIRk29YGaf1QuypLHBZ2foBj08fnwjgDiTMG9ptR9x2OvSsbj/0W9HGY7eQ3skcA"; # unencrypted version in SOPS
          consent_mode = "implicit";
          public = false;
          authorization_policy = "two_factor";
          redirect_uris = [
            "https://outline.${config.mySystem.rootDomain}/auth/oidc.callback"
          ];
          scopes = [
            "email"
            "openid"
            "profile"
          ];
          token_endpoint_auth_method = "client_secret_post";
        }
      ];

      postgresql.userDatabases = [
        {
          username = "outline";
          passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/OUTLINE_DB_PASSWORD".path;
          databases = [ "outline" ];
        }
      ];

      redis.servers.outline = 6383;
    };

    virtualisation.oci-containers.containers.outline = svc.mkContainer {
      cfg = {
        image = "outlinewiki/outline:0.87.0@sha256:3f31ddcd5ccc5b286b98290e9a5ae0c1c21a6c5a08c81d79869fb0b2e105dcce";
        environment = {
          ENABLE_UPDATES = "false";
          FILE_STORAGE = "local";
          FILE_STORAGE_LOCAL_ROOT_DIR = "/var/lib/outline/data";
          FORCE_HTTPS = "true";
          OIDC_AUTH_URI = "https://authelia.${config.mySystem.rootDomain}/api/oidc/authorization";
          OIDC_CLIENT_ID = "outline";
          OIDC_DISPLAY_NAME = "Authelia";
          OIDC_SCOPES = "openid profile email";
          OIDC_TOKEN_URI = "https://authelia.${config.mySystem.rootDomain}/api/oidc/token";
          OIDC_USERINFO_URI = "https://authelia.${config.mySystem.rootDomain}/api/oidc/userinfo";
          OIDC_USERNAME_CLAIM = "preferred_username";
          PGSSLMODE = "disable";
          SMTP_FROM_EMAIL = config.mySystem.notificationSender;
          SMTP_HOST = "maddy";
          SMTP_PORT = "25";
          SMTP_SECURE = "false";
          URL = "https://outline.${config.mySystem.rootDomain}";
        };
        environmentFiles = [ "/run/outline/env" ];
        volumes = [ "${cfg.dataDir}/data:/var/lib/outline/data" ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
          "--add-host=authelia.${config.mySystem.rootDomain}:${config.mySystemApps.docker.network.private.hostIP}"
        ];
      };
    };

    services = {
      nginx.virtualHosts.outline = svc.mkNginxVHost {
        host = "outline";
        proxyPass = "http://outline.docker:3000";
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "outline" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "outline";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-outline = {
      preStart = lib.mkAfter (
        ''
          mkdir -p "${cfg.dataDir}/data" "/run/outline"
          chown 1001:1001 "${cfg.dataDir}" "${cfg.dataDir}/data"
        ''
        + (svc.mkSecretEnvFile {
          inherit secretEnvs;
          inherit (cfg) sopsSecretPrefix;
          dest = "/run/outline/env";
        })
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.Outline = svc.mkHomepage "outline" // {
        icon = "outline.png";
        description = "Notetaking system";
      };
    };
  };
}
