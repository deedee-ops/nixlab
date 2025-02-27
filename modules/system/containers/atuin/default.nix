{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.atuin;
  secretEnvs = [
    "ATUIN__POSTGRES_PASSWORD"
  ];
in
{
  options.mySystemApps.atuin = {
    enable = lib.mkEnableOption "atuin server container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/atuin/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for atuin are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "atuin";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "atuin";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/ATUIN__POSTGRES_PASSWORD".path;
        databases = [ "atuin" ];
      }
    ];

    virtualisation.oci-containers.containers.atuin = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/atuin:18.4.0@sha256:c84e3bb5b337c933b8ae64aa6575a14affe91411e87dd7255a4d0c6f90c9806b";
        environment = {
          ATUIN__POSTGRES_DATABASE = "atuin";
          ATUIN__POSTGRES_HOST = "host.docker.internal";
          ATUIN__POSTGRES_SSLMODE = "disable";
          ATUIN__POSTGRES_USERNAME = "atuin";
          ATUIN_HOST = "0.0.0.0";
          ATUIN_OPEN_REGISTRATION = "true";
          RUST_LOG = "info,atuin_server=debug";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes = svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
        };
      };
    };

    services = {
      nginx.virtualHosts.atuin = svc.mkNginxVHost {
        host = "atuin";
        proxyPass = "http://atuin.docker:8888";
        useAuthelia = false;
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "atuin" ]; };
    };
  };
}
