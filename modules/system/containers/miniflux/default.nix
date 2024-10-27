{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.miniflux;
  secretEnvs = [
    "ADMIN_PASSWORD"
    "ADMIN_USERNAME"
    "MINIFLUX__POSTGRES_PASSWORD"
  ];
in
{
  options.mySystemApps.miniflux = {
    enable = lib.mkEnableOption "miniflux container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/miniflux/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for miniflux are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "miniflux";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "miniflux";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/MINIFLUX__POSTGRES_PASSWORD".path;
        databases = [ "miniflux" ];
      }
    ];

    virtualisation.oci-containers.containers.miniflux = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/miniflux:2.2.1@sha256:f1250fa8d63585e4b323a054e1e16e7099a6cd81e80f8a52adc694698f67f76b";
        environment =
          {
            AUTH_PROXY_HEADER = "Remote-User";
            CREATE_ADMIN = "1";
            POLLING_PARSING_ERROR_LIMIT = "3";
            RUN_MIGRATIONS = "1";
            MINIFLUX__POSTGRES_DATABASE = "miniflux";
            MINIFLUX__POSTGRES_HOST = "host.docker.internal";
            MINIFLUX__POSTGRES_SSLMODE = "disable";
            MINIFLUX__POSTGRES_USERNAME = "miniflux";
          }
          // lib.optionalAttrs config.mySystemApps.piped.enable {
            YOUTUBE_EMBED_URL_OVERRIDE = "https://piped.${config.mySystem.rootDomain}/embed/";
          }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes = svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
        };
      };
      opts = {
        # fetching RSS feeds
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.miniflux = svc.mkNginxVHost {
        host = "miniflux";
        proxyPass = "http://miniflux.docker:3000";
      };
      nginx.virtualHosts.miniflux-api = svc.mkNginxVHost {
        host = "miniflux-api";
        proxyPass = "http://miniflux.docker:3000";
        useAuthelia = false;
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "miniflux" ]; };
    };
  };
}
