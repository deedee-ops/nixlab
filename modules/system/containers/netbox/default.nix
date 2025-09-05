{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.netbox;
  secretEnvs = [
    "db_password"
    "redis_password"
    "redis_cache_password"
    "secret_key"
  ];
in
{
  imports = [
    ./housekeeping.nix
    ./netbox.nix
    ./worker.nix
  ];

  options.mySystemApps.netbox = {
    enable = lib.mkEnableOption "netbox container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/netbox";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/netbox/env";
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        CORS_ORIGIN_ALLOW_ALL = "True";
        DB_HOST = "host.docker.internal";
        DB_NAME = "netbox";
        DB_USER = "netbox";
        EMAIL_FROM = config.mySystem.notificationSender;
        EMAIL_PORT = "25";
        EMAIL_SERVER = "maddy";
        EMAIL_USE_SSL = "false";
        EMAIL_USE_TLS = "false";
        GRAPHQL_ENABLED = "true";
        HOUSEKEEPING_INTERVAL = "86400";
        MEDIA_ROOT = "/opt/netbox/netbox/media";
        METRICS_ENABLED = "false";
        REDIS_CACHE_DATABASE = "1";
        REDIS_CACHE_HOST = "host.docker.internal";
        REDIS_CACHE_PORT = "6385";
        REDIS_CACHE_SSL = "false";
        REDIS_DATABASE = "0";
        REDIS_HOST = "host.docker.internal";
        REDIS_PORT = "6385";
        REDIS_SSL = "false";
        RELEASE_CHECK_URL = "https://api.github.com/repos/netbox-community/netbox/releases";
        REMOTE_AUTH_ENABLED = "true";
        REMOTE_AUTH_BACKEND = "netbox.authentication.RemoteUserBackend";
        SKIP_SUPERUSER = "true";
        TIME_ZONE = config.mySystem.time.timeZone;
        WEBHOOKS_ENABLED = "true";
      };
      internal = true;
    };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default =
        svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
          secretPath = "/run/secrets";
        }
        ++ [
          "${cfg.dataDir}/config:/etc/netbox/config:z,ro"
          "${cfg.dataDir}/media:/opt/netbox/netbox/media"
          "${cfg.dataDir}/reports:/opt/netbox/netbox/reports"
          "${cfg.dataDir}/scripts:/opt/netbox/netbox/scripts"
        ];
      internal = true;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for netbox are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "netbox";
    };

    mySystemApps = {
      postgresql.userDatabases = [
        {
          username = "netbox";
          passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/db_password".path;
          databases = [ "netbox" ];
        }
      ];
      redis = {
        enable = true;
        servers.netbox = 6385;
      };
    };
  };
}
