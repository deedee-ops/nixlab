{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.firefoxsync;
in
{
  imports = [
    ./mysql.nix
  ];

  options.mySystemApps.firefoxsync = {
    enable = lib.mkEnableOption "firefoxsync container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/firefoxsync";
    };
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing firefoxsync envs.";
      default = "system/apps/firefoxsync/envfile";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for firefoxsync are disabled!") ];
    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.firefoxsync = svc.mkContainer {
      cfg = {
        image = "ghcr.io/porelli/firefox-sync:syncstorage-rs-mysql-latest@sha256:c5e06bf29ecc174e8b1d8d80bd19f6548fbd792333014d5e97a546bc9b072633";
        dependsOn = [ "firefoxsync-mysql" ];
        environment = {
          SYNC_HOST = "0.0.0.0";
          SYNC_HUMAN_LOGS = "1";
          SYNC_TOKENSERVER__ENABLED = "true";
          SYNC_TOKENSERVER__RUN_MIGRATIONS = "true";
          SYNC_TOKENSERVER__NODE_TYPE = "mysql";
          SYNC_TOKENSERVER__FXA_EMAIL_DOMAIN = "api.accounts.firefox.com";
          SYNC_TOKENSERVER__FXA_OAUTH_SERVER_URL = "https://oauth.accounts.firefox.com/v1";
          SYNC_TOKENSERVER__ADDITIONAL_BLOCKING_THREADS_FOR_FXA_REQUESTS = "2";
          RUST_LOG = "info";
        };
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
      };
      opts = {
        # accessing auth server
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.firefoxsync = svc.mkNginxVHost {
        host = "firefoxsync";
        proxyPass = "http://firefoxsync.docker:8000";
        useAuthelia = false;
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "firefoxsync";
          paths = [ cfg.dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };
  };
}
