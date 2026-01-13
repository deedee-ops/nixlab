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
        image = "ghcr.io/atuinsh/atuin:v18.11.0@sha256:18dba8938704706806d3c1133629ff2658c08bfa7815d71a916a8f072b61945b";
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
