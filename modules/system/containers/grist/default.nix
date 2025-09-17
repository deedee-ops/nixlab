{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.grist;
  secretEnvs = [
    "GRIST_OIDC_IDP_CLIENT_SECRET"
    "GRIST_SESSION_SECRET"
  ]
  ++ lib.optionals config.mySystemApps.minio.enable [
    "GRIST_DOCS_MINIO_ACCESS_KEY"
    "GRIST_DOCS_MINIO_SECRET_KEY"
  ];
in
{
  options.mySystemApps.grist = {
    enable = lib.mkEnableOption "grist container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    orgName = lib.mkOption {
      type = lib.types.str;
      description = "Grist organization name.";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/grist";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/grist/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for grist are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "grist";
    };

    virtualisation.oci-containers.containers.grist = svc.mkContainer {
      cfg = {
        image = "gristlabs/grist:1.7.3@sha256:6276701cfaaaf4a11f5ac77afa31faadab1aee24f0f2ccd5d68a55075e53802a";
        dependsOn = lib.optionals config.mySystemApps.minio.enable [ "minio" ];
        environment = {
          APP_HOME_URL = "https://grist.${config.mySystem.rootDomain}";
          GRIST_ALLOW_AUTOMATIC_VERSION_CHECKING = "false";
          GRIST_DEFAULT_EMAIL = "admin@${config.mySystem.rootDomain}";
          GRIST_FORCE_LOGIN = "true";
          GRIST_MINIO_BUCKET = "grist";
          GRIST_NODEMAILER_CONFIG = ''{"host":"maddy","port":25}'';
          GRIST_NODEMAILER_SENDER = ''{"name":"Grist Admin","email":"${config.mySystem.notificationSender}"}'';
          GRIST_OIDC_IDP_CLIENT_ID = "grist";
          GRIST_OIDC_IDP_ISSUER = "https://authelia.${config.mySystem.rootDomain}";
          GRIST_OIDC_IDP_SCOPES = "openid profile email";
          GRIST_OIDC_IDP_SKIP_END_SESSION_ENDPOINT = "true";
          GRIST_OIDC_SP_HOST = "https://grist.${config.mySystem.rootDomain}";
          GRIST_SANDBOX_FLAVOR = "gvisor";
          GRIST_SINGLE_ORG = cfg.orgName;
          GRIST_TELEMETRY_LEVEL = "off";
        }
        // lib.optionalAttrs config.mySystemApps.minio.enable {
          GRIST_DOCS_MINIO_ENDPOINT = "s3.${config.mySystem.rootDomain}";
          GRIST_DOCS_MINIO_BUCKET = "grist";
        };
        volumes = [
          "${cfg.dataDir}:/persist"
        ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--cap-add=CAP_FSETID"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
        ];
      };
      opts = {
        # downloading widgets and plugins
        allowPublic = true;
        readOnlyRootFilesystem = false;

        inherit (cfg) sopsSecretPrefix;
        inherit secretEnvs;
      };
    };

    services = {
      nginx.virtualHosts.grist = svc.mkNginxVHost {
        host = "grist";
        proxyPass = "http://grist.docker:8484";
        autheliaIgnorePaths = [
          "/status" # internal healthcheck
        ];
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "grist";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-grist = {
      preStart = lib.mkAfter ''
        chown 1001:1001 "${cfg.dataDir}"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps = {
      authelia.oidcClients = [
        {
          client_id = "grist";
          client_name = "grist";
          client_secret = "$pbkdf2-sha512$310000$kAu5PliP.9G9kOk7kLnbZw$HSYio2UJllRt8Yr1/VRXYnrz40//0n.m/ZouSjYgQixRB5hoFNVg.hrWWP7FFuE4zs01gYpV5T7820WFcO42Mw"; # unencrypted version in SOPS
          consent_mode = "implicit";
          public = false;
          authorization_policy = "two_factor";
          redirect_uris = [
            "https://grist.${config.mySystem.rootDomain}/oauth2/callback"
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

      homepage = {
        services.Apps.Grist = svc.mkHomepage "grist" // {
          description = "Data visualization spreadsheet";
        };
      };
    };
  };
}
