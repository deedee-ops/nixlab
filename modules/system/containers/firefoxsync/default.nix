{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.firefoxsync;
  secretEnvs = [
    "FIREFOXSYNC__POSTGRES_PASSWORD"
    "FIREFOXSYNC__SECRET"
  ];
in
{
  options.mySystemApps.firefoxsync = {
    enable = lib.mkEnableOption "firefoxsync container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/firefoxsync/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for firefoxsync are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "firefoxsync";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "firefoxsync";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/FIREFOXSYNC__POSTGRES_PASSWORD".path;
        databases = [ "firefoxsync" ];
      }
    ];

    virtualisation.oci-containers.containers.firefoxsync = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/firefoxsync:1.9.1@sha256:d0e0cc94d30048aa464b4d4f3cf89328d413183ce1c791ca577037eae5c65fed";
        environment = {
          FIREFOXSYNC__PUBLIC_URL = "https://firefoxsync.${config.mySystem.rootDomain}";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes = svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
        };
      };
    };

    services = {
      nginx.virtualHosts.firefoxsync = svc.mkNginxVHost {
        host = "firefoxsync";
        proxyPass = "http://firefoxsync.docker:3000";
        useAuthelia = false;
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "firefoxsync" ]; };
    };
  };
}
