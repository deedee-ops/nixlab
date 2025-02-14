{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.bitmagnet;
  secretEnvs = [
    "POSTGRES_PASSWORD"
    # "TMDB_API_KEY"
  ];
in
{
  options.mySystemApps.bitmagnet = {
    enable = lib.mkEnableOption "bitmagnet container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/bitmagnet";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/bitmagnet/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for bitmagnet are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "bitmagnet";
    };

    mySystemApps = {
      gluetun.extraPorts = [
        "3333"
        "3334/tcp"
        "3334/udp"
      ];

      postgresql.userDatabases = [
        {
          username = "bitmagnet";
          passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/POSTGRES_PASSWORD".path;
          databases = [ "bitmagnet" ];
        }
      ];
    };

    virtualisation.oci-containers.containers.bitmagnet = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/bitmagnet:0.9.5";
        environment = {
          CLASSIFIER_DELETE_XXX = "true";
          POSTGRES_NAME = "bitmagnet";
          POSTGRES_USER = "bitmagnet";
          POSTGRES_HOST = "host.docker.internal";
          TMDB_ENABLED = "false";
        } // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [ "${cfg.dataDir}/config:/root/.config/bitmagnet" ];
      };

      opts = {
        routeThroughVPN = true;
      };
    };

    services = {
      nginx.virtualHosts.bitmagnet = svc.mkNginxVHost {
        host = "bitmagnet";
        proxyPass = "http://gluetun.docker:3333";
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "bitmagnet" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "bitmagnet";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-bitmagnet = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Bitmagnet = svc.mkHomepage "bitmagnet" // {
        description = "DHT cache";
      };
    };
  };
}
