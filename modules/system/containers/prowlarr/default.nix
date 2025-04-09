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
    customDefinitions = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "List of paths to custom indexer definitions.";
      default = [ ];
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
        image = "ghcr.io/deedee-ops/prowlarr-devel:1.33.3.5008@sha256:19ac64b2606410666fb818f327574d0fa27bacb8515f899cf54e5ca9e3afa357";
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
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ builtins.map (
            def: "${def}:/config/Definitions/Custom/${builtins.baseNameOf def}:ro"
          ) cfg.customDefinitions;
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
