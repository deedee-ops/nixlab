{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.atuin;
  secretEnvs = [
    "ATUIN_DB_URI"
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
        image = "ghcr.io/atuinsh/atuin:v18.10.0@sha256:4a29feda6f352581ece849807445fe1f50f2074b4643b7bfe62b27e23705b068";
        cmd = [
          "server"
          "start"
        ];
        environment = {
          ATUIN_CONFIG_DIR = "/config";
          ATUIN_HOST = "0.0.0.0";
          ATUIN_OPEN_REGISTRATION = "false";
          RUST_LOG = "info,atuin_server=debug";
        };
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/config,tmpfs-mode=1777"
        ];
      };
      opts = {
        inherit (cfg) sopsSecretPrefix;
        inherit secretEnvs;
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
