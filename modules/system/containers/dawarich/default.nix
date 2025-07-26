{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.dawarich;
  secretEnvs = [
    "DATABASE_PASSWORD"
    "REDIS_URL"
    "SECRET_KEY_BASE"
  ];
in
{
  options.mySystemApps.dawarich = {
    enable = lib.mkEnableOption "dawarich container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/dawarich";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/dawarich/env";
    };
    internalPhoton = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use internal Photon instead of the official OSM one.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for dawarich are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "dawarich";
    };

    mySystemApps = {
      postgresql = {
        enablePostGIS = true;
        userDatabases = [
          {
            username = "dawarich";
            passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/DATABASE_PASSWORD".path;
            databases = [ "dawarich" ];
          }
        ];
        initSQL = {
          dawarich = ''
            CREATE EXTENSION IF NOT EXISTS postgis CASCADE;
          '';
        };
      };
      redis.servers.dawarich = 6386;
    };

    virtualisation.oci-containers.containers =
      let
        envs =
          {
            APPLICATION_HOSTS = "localhost,127.0.0.1,dawarich.${config.mySystem.rootDomain}";
            APPLICATION_PROTOCOL = "http";
            DATABASE_HOST = "host.docker.internal";
            DATABASE_NAME = "dawarich";
            DATABASE_PORT = "5432";
            DATABASE_USERNAME = "dawarich";
            DISABLE_TELEMETRY = "true";
            MIN_MINUTES_SPENT_IN_CITY = "60";
            PROMETHEUS_EXPORTER_ENABLED = "false";
            RAILS_ENV = "production";
            RAILS_LOG_TO_STDOUT = "true";
            SELF_HOSTED = "true";
            STORE_GEODATA = "true";
            TIME_ZONE = config.mySystem.time.timeZone;
          }
          // lib.optionalAttrs cfg.internalPhoton {
            PHOTON_API_HOST = "photon:2322";
            PHOTON_API_USE_HTTPS = "false";
          };
      in
      {
        dawarich = svc.mkContainer {
          cfg = {
            user = "65000:65000";
            image = "freikin/dawarich:0.30.4@sha256:65139f48d348231134c10ff8483ccf94bab34e9ba7df4dbab11eb83bef7d2b8e";
            dependsOn = lib.optionals cfg.internalPhoton [ "photon" ];
            cmd = [
              "bin/rails"
              "server"
              "-p"
              "3000"
              "-b"
              "0.0.0.0"
            ];
            environment = envs // {
              MIN_MINUTES_SPENT_IN_CITY = "60";
              RAILS_LOG_TO_STDOUT = "true";
            };
            volumes = [
              "${cfg.dataDir}/public:/var/app/public"
              "${cfg.dataDir}/storage:/var/app/storage"
              # "${cfg.dataDir}/imports:/var/app/tmp/imports/watched"
            ];
            extraOptions = [
              "--mount"
              "type=tmpfs,destination=/var/app/tmp,tmpfs-mode=1777"
            ];
          };
          opts = {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          };
        };
        dawarich-worker = svc.mkContainer {
          cfg = {
            user = "65000:65000";
            image = "freikin/dawarich:0.30.4@sha256:65139f48d348231134c10ff8483ccf94bab34e9ba7df4dbab11eb83bef7d2b8e";
            dependsOn = [ "dawarich" ];
            cmd = [ "sidekiq" ];
            environment = envs // {
              BACKGROUND_PROCESSING_CONCURRENCY = "10";
            };
            volumes = [
              "${cfg.dataDir}/public:/var/app/public"
              "${cfg.dataDir}/storage:/var/app/storage"
              # "${cfg.dataDir}/imports:/var/app/tmp/imports/watched"
            ];
          };
          opts = {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          };
        };
      };

    systemd.services.docker-dawarich = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/public" "${cfg.dataDir}/storage" "${cfg.dataDir}/imports"
        chown 65000:65000 "${cfg.dataDir}" "${cfg.dataDir}/public" "${cfg.dataDir}/storage" "${cfg.dataDir}/imports"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    services = {
      nginx.virtualHosts.dawarich = svc.mkNginxVHost {
        host = "dawarich";
        proxyPass = "http://dawarich.docker:3000";
        useAuthelia = true;
        autheliaIgnorePaths = [
          "/api"
        ];
        customCSP = ''
          default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data: mediastream: blob: wss:;
          img-src 'self' https://tile.openstreetmap.org https://*.tile.openstreetmap.org https://unpkg.com;
          style-src-elem 'self' 'unsafe-inline' https://unpkg.com https://cdnjs.cloudflare.com;
          script-src-elem 'self' 'unsafe-inline' https://unpkg.com;
          object-src 'none';
        '';
      };

      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "dawarich" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "dawarich";
          paths = [ cfg.dataDir ];
        }
      );
    };

    mySystemApps.homepage = {
      services.Apps.Dawarich = svc.mkHomepage "dawarich" // {
        description = "Location tracker";
      };
    };
  };
}
