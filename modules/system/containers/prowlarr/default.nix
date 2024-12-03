{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.prowlarr;
  secretEnvs = [
    "PROWLARR__AUTH__APIKEY"
    "PROWLARR__POSTGRES__PASSWORD"
  ];
in
{
  options.mySystemApps.prowlarr = {
    enable = lib.mkEnableOption "prowlarr container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/prowlarr/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for prowlarr are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "prowlarr";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "prowlarr";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/PROWLARR__POSTGRES__PASSWORD".path;
        databases = [ "prowlarr" ];
      }
    ];

    virtualisation.oci-containers.containers.prowlarr = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/prowlarr-devel:1.27.0.4852@sha256:eb008be583cec0bf317a215807a24f33fef307d2ce233ed9e3a6c9a0ad7a9542";
        environment = {
          PROWLARR__APP__INSTANCENAME = "Prowlarr";
          PROWLARR__APP__THEME = "dark";
          PROWLARR__AUTH__METHOD = "External";
          PROWLARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
          PROWLARR__LOG__ANALYTICSENABLED = "False";
          PROWLARR__LOG__DBENABLED = "False";
          PROWLARR__LOG__LEVEL = "info";
          PROWLARR__POSTGRES__HOST = "host.docker.internal";
          PROWLARR__POSTGRES__MAINDB = "prowlarr";
          PROWLARR__POSTGRES__USER = "prowlarr";
          PROWLARR__UPDATE__BRANCH = "develop";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes = svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
        };
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/config,tmpfs-mode=1777"
        ];
      };
      opts = {
        # downloading metadata
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.prowlarr = svc.mkNginxVHost {
        host = "prowlarr";
        proxyPass = "http://prowlarr.docker:9696";
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "prowlarr" ]; };
    };

    mySystemApps.homepage = {
      services.Media.Prowlarr = svc.mkHomepage "prowlarr" // {
        description = "Torrent tracker management";
        widget = {
          type = "prowlarr";
          url = "http://prowlarr:9696";
          key = "@@PROWLARR_API_KEY@@";
          fields = [
            "numberOfGrabs"
            "numberOfFailGrabs"
            "numberOfQueries"
            "numberOfFailQueries"
          ];
        };
      };
      secrets.PROWLARR_API_KEY =
        config.sops.secrets."${cfg.sopsSecretPrefix}/PROWLARR__AUTH__APIKEY".path;
    };

  };
}
