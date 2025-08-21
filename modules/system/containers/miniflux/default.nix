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
    "DATABASE_URL"
    "HOMEPAGE_API_KEY"
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
        image = "ghcr.io/miniflux/miniflux:2.2.12@sha256:b435a1ea2408f996c8d4c00c4f46523fa9203971ee1e85b1fe7ad3f0e7ae617f";
        user = "65000:65000";
        environment = {
          AUTH_PROXY_HEADER = "Remote-User";
          CREATE_ADMIN = "1";
          LISTEN_ADDR = "0.0.0.0:3000";
          POLLING_PARSING_ERROR_LIMIT = "3";
          RUN_MIGRATIONS = "1";
        }
        // lib.optionalAttrs config.mySystemApps.piped.enable {
          YOUTUBE_EMBED_URL_OVERRIDE = "https://piped.${config.mySystem.rootDomain}/embed/";
        }
        // svc.mkContainerSecretsEnv { inherit secretEnvs; };
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
        customCSP = ''
          default-src 'self' 'unsafe-inline' data: blob: wss: *.${config.mySystem.rootDomain};
          img-src 'self' data: https:;
          media-src 'self' https:;
          object-src 'none';
        '';
      };
      nginx.virtualHosts.miniflux-api = svc.mkNginxVHost {
        host = "miniflux-api";
        proxyPass = "http://miniflux.docker:3000";
        useAuthelia = false;
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "miniflux" ]; };
    };

    mySystemApps.homepage = {
      services.Apps.Miniflux = svc.mkHomepage "miniflux" // {
        description = "RSS Reader";
        widget = {
          type = "miniflux";
          url = "http://miniflux:3000";
          key = "@@MINIFLUX_API_KEY@@";
          fields = [
            "unread"
            "read"
          ];
        };
      };
      secrets.MINIFLUX_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/HOMEPAGE_API_KEY".path;
    };
  };
}
