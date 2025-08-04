{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.immich;
  secretEnvs = [
    "ADMIN_API_KEY"
    "AJGON_API_KEY"
    "DB_PASSWORD"
    "OIDC_SECRET_RAW"
  ];

  dockerEnv = {
    DB_DATABASE_NAME = "immich";
    DB_HOSTNAME = "host.docker.internal";
    DB_USERNAME = "immich";
    IMMICH_CONFIG_FILE = "/config/config.json";
    IMMICH_ENV = "production";
    IMMICH_MACHINE_LEARNING_URL = "http://immich-machine-learning:3003";
    IMMICH_MEDIA_LOCATION = "/data";
    IMMICH_SERVER_URL = "http://immich-server:2283";
    MPLCONFIGDIR = "/cache/matplotlib";
    NODE_ENV = "production";
    REDIS_HOSTNAME = "host.docker.internal";
    REDIS_PASSWORD_FILE = "/secrets/REDIS_PASSWORD";
    REDIS_PORT = "6382";
    TRANSFORMERS_CACHE = "/cache";
  }
  // svc.mkContainerSecretsEnv { inherit secretEnvs; }
  // lib.optionalAttrs config.mySystem.networking.completelyDisableIPV6 { IMMICH_HOST = "0.0.0.0"; };
in
{
  imports = [
    (import ./album-creator.nix { inherit config lib pkgs; })
    (import ./machine-learning.nix {
      inherit
        config
        lib
        svc
        dockerEnv
        secretEnvs
        ;
    })
    (import ./server.nix {
      inherit
        config
        lib
        svc
        dockerEnv
        secretEnvs
        ;
    })
  ];

  options.mySystemApps.immich = {
    enable = lib.mkEnableOption "immich container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    dataPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing immich data (mostly thumbnails).";
    };
    photosPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Path to directory containing photos to import. Disabled if null.";
      default = null;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/immich/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for immich are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "immich-server";
    };

    mySystemApps = {
      authelia.oidcClients = [
        {
          client_id = "immich";
          client_name = "Immich";
          client_secret = "$pbkdf2-sha512$310000$deiPEmRZZJdi8qd2FiL4tg$nE2gD0Vfh5TOJKq51AfHcrqrQ1tM971UVx8yXqo2DRjrtAmrwewFquGrDZ4IURajPcazwBHfbX.mL8Od.o48Rw"; # unencrypted version in SOPS
          consent_mode = "implicit";
          public = false;
          authorization_policy = "two_factor";
          require_pkce = false;
          redirect_uris = [
            "app.immich:///oauth-callback"
            "https://immich.${config.mySystem.rootDomain}/auth/login"
            "https://immich.${config.mySystem.rootDomain}/user-settings"
          ];
          scopes = [
            "email"
            "openid"
            "profile"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      postgresql = {
        enableVectorchord = true;
        userDatabases = [
          {
            username = "immich";
            passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/DB_PASSWORD".path;
            databases = [ "immich" ];
          }
        ];
        initSQL = {
          immich = ''
            ALTER DATABASE immich OWNER TO immich;
            ALTER SCHEMA public OWNER TO immich;

            CREATE EXTENSION IF NOT EXISTS vchord CASCADE;
            CREATE EXTENSION IF NOT EXISTS earthdistance CASCADE;

            ALTER EXTENSION vchord UPDATE;
            REINDEX INDEX face_index;
            REINDEX INDEX clip_index;
          '';
        };
      };

      redis.servers.immich = 6382;
    };

    services = {
      nginx.virtualHosts.immich = svc.mkNginxVHost {
        host = "immich";
        proxyPass = "http://immich-server.docker:2283";
        autheliaIgnorePaths = [
          "/.well-known"
          "/api"
        ];
        customCSP = ''
          default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data:
          mediastream: blob: wss: https://static.immich.cloud https://tiles.immich.cloud
          https://*.${config.mySystem.rootDomain}; object-src 'none';
        '';
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "immich" ]; };
    };

    mySystemApps.homepage = {
      services.Apps.Immich = svc.mkHomepage "immich" // {
        container = "immich-server";
        description = "Photos library";
        widget = {
          type = "immich";
          url = "http://immich-server:2283";
          key = "@@IMMICH_API_KEY@@";
          version = 2;
          fields = [
            "photos"
            "videos"
          ];
        };
      };
      secrets.IMMICH_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/ADMIN_API_KEY".path;
    };
  };
}
