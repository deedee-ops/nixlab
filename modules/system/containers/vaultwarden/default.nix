{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.vaultwarden;
  secretEnvs = [
    "ADMIN_TOKEN"
    "DATABASE_URL"
    "VAULTWARDEN_DB_PASSWORD"
  ];
in
{
  options.mySystemApps.vaultwarden = {
    enable = lib.mkEnableOption "vaultwarden container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/vaultwarden";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/vaultwarden/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for vaultwarden are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "vaultwarden";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "vaultwarden";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/VAULTWARDEN_DB_PASSWORD".path;
        databases = [ "vaultwarden" ];
      }
    ];

    virtualisation.oci-containers.containers.vaultwarden = svc.mkContainer {
      cfg = {
        image = "ghcr.io/dani-garcia/vaultwarden:1.32.2@sha256:c07f5319d20bdbd58a19d7d779a1e97159ce25cb95572baa947c70f58589937c";
        environment = {
          DATA_FOLDER = "/config";
          DISABLE_ICON_DOWNLOAD = "true";
          DOMAIN = "https://vaultwarden.${config.mySystem.rootDomain}";
          INVITATIONS_ALLOWED = "false";
          PASSWORD_HINTS_ALLOWED = "false";
          ROCKET_LIMITS = "{json=104857600}";
          ROCKET_PORT = "3000";
          SHOW_PASSWORD_HINT = "false";
          SIGNUPS_ALLOWED = "false";
          SMTP_FROM = config.mySystem.notificationSender;
          SMTP_HOST = "host.docker.internal";
          SMTP_PORT = "25";
          SMTP_SECURITY = "off";
        } // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [ "${cfg.dataDir}/config:/config" ];
      };
    };

    services = {
      nginx.virtualHosts.vaultwarden = svc.mkNginxVHost "vaultwarden" "http://vaultwarden.docker:3000";
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "vaultwarden" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "vaultwarden";
          paths = [ cfg.dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };
  };
}
