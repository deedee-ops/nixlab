{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.firefly-iii;
  secretEnvs = [
    "APP_KEY"
    "DB_PASSWORD"
    "FIREFLY_III_TOKEN"
    "HOMEPAGE_API_KEY"
  ];
in
{
  options.mySystemApps.firefly-iii = {
    enable = lib.mkEnableOption "firefly-iii container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/firefly-iii/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for firefly-iii are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "firefly-iii";
    };

    mySystemApps = {
      postgresql.userDatabases = [
        {
          username = "firefly";
          passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/DB_PASSWORD".path;
          databases = [ "firefly" ];
        }
      ];
      redis.servers.firefly-iii = 6380;
    };

    virtualisation.oci-containers.containers.firefly-iii = svc.mkContainer {
      cfg = {
        image = "docker.io/fireflyiii/core:version-6.2.20";
        user = "33:65000";
        environment = {
          APP_URL = "https://firefly.${config.mySystem.rootDomain}";
          AUTHENTICATION_GUARD = "remote_user_guard";
          AUTHENTICATION_GUARD_EMAIL = "HTTP_REMOTE_EMAIL";
          AUTHENTICATION_GUARD_HEADER = "HTTP_REMOTE_EMAIL";
          DB_CONNECTION = "pgsql";
          DB_DATABASE = "firefly";
          DB_HOST = "host.docker.internal";
          DB_PORT = "5432";
          DB_USERNAME = "firefly";
          ENABLE_EXCHANGE_RATES = "true";
          ENABLE_EXTERNAL_RATES = "true";
          MAIL_ENCRYPTION = "null";
          MAIL_FROM = config.mySystem.notificationSender;
          MAIL_HOST = "maddy";
          MAIL_MAILER = "smtp";
          MAIL_PORT = "25";
          SEND_TELEMETRY = "false";
          SITE_OWNER = config.mySystem.notificationSender;
          TRUSTED_PROXIES = "**";

          CACHE_DRIVER = "redis";
          SESSION_DRIVER = "redis";
          REDIS_SCHEME = "tcp";
          REDIS_HOST = "host.docker.internal";
          REDIS_PASSWORD_FILE = "/secrets/REDIS_PASSWORD";
          REDIS_PORT = "6380";
        } // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/config,tmpfs-mode=1777"
        ];
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${
              config.sops.secrets."${config.mySystemApps.redis.passFileSopsSecret}".path
            }:/secrets/REDIS_PASSWORD:ro"
          ]
          ++ lib.optionals config.mySystem.networking.completelyDisableIPV6 [
            "${pkgs.writeText "0-disable-ipv6.sh" "sed -i'' 's@listen \\[::\\].*@@g' /etc/nginx/site-opts.d/*"}:/etc/entrypoint.d/0-disable-ipv6.sh"
          ];
      };
      opts = {
        # download exchange rates
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.firefly-iii = svc.mkNginxVHost {
        host = "firefly";
        proxyPass = "http://firefly-iii.docker:8080";
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "firefly" ]; };
    };

    systemd = {
      services.docker-firefly-iii-cron = {
        description = "Trigger firefly iii cron.";
        path = [ (pkgs.curlFull.override { c-aresSupport = true; }) ]; # c-aresSupport enables `--dns-servers` option
        serviceConfig.Type = "simple";
        script = ''
          curl --silent --show-error --fail --dns-servers 127.0.0.1:5533 "http://firefly-iii.docker:8080/api/v1/cron/$(cat ${
            config.sops.secrets."${cfg.sopsSecretPrefix}/FIREFLY_III_TOKEN".path
          })"
        '';
      };

      timers.docker-firefly-iii-cron = {
        description = "Firefly III cron timer.";
        wantedBy = [ "timers.target" ];
        partOf = [ "docker-firefly-iii-cron.service" ];
        timerConfig.OnCalendar = "0:00";
        timerConfig.Persistent = "true";
      };
    };

    mySystemApps.homepage = {
      services.Apps.FireflyIII = svc.mkHomepage "firefly" // {
        container = "firefly-iii";
        description = "Personal finance management";
        widget = {
          type = "firefly";
          url = "http://firefly-iii:8080";
          key = "@@FIREFLYIII_API_KEY@@";
          fields = [
            "networth"
            "budget"
          ];
        };
      };
      secrets.FIREFLYIII_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/HOMEPAGE_API_KEY".path;
    };
  };
}
