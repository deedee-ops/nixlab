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
    backup = lib.mkEnableOption "postgresql and data backup" // {
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
        image = "ghcr.io/dani-garcia/vaultwarden:1.32.6@sha256:0498b67709f769fee36b1acf02f69e8d9981b051aa5b8200878d938bd537d39d";
        user = "65000:65000";
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
          SMTP_HOST = "maddy";
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
      nginx.virtualHosts.vaultwarden = svc.mkNginxVHost {
        host = "vaultwarden";
        proxyPass = "http://vaultwarden.docker:3000";
        useAuthelia = false;
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "vaultwarden" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "vaultwarden";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-vaultwarden = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.Vaultwarden = svc.mkHomepage "vaultwarden" // {
        description = "Password manager";
      };
    };
  };
}
