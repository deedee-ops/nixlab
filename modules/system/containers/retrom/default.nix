{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.retrom;
  secretEnvs = [
    "DATABASE_PASSWORD"
    "DATABASE_URL"
    "IGDB_CLIENT_ID"
    "IGDB_CLIENT_SECRET"
  ];
in
{
  options.mySystemApps.retrom = {
    enable = lib.mkEnableOption "retrom container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/retrom";
    };
    romsPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing ROMs.";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/retrom/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for retrom are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "retrom";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "retrom";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/DATABASE_PASSWORD".path;
        databases = [ "retrom" ];
      }
    ];

    virtualisation.oci-containers.containers.retrom = svc.mkContainer {
      cfg = {
        image = "ghcr.io/jmberesford/retrom-service:v0.7.36@sha256:9e0524a1455457c30b9618434fd789760d201d04d85cd16ec8b4b6e91cbaf45a";
        user = "1000:1000";
        volumes = [
          "${cfg.dataDir}/config:/app/config"
          "${cfg.romsPath}:/roms"
        ];
      };
      opts = {
        # downloading covers and assets
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.retrom = svc.mkNginxVHost {
        host = "retrom";
        proxyPass = "http://retrom.docker:5101";
        customCSP = ''
          default-src 'self' 'unsafe-inline' data: blob: wss:;
          frame-src 'self' https://www.youtube.com;
          img-src 'self' data: https://images.igdb.com;
          object-src 'none';
          style-src 'self' 'unsafe-inline' data: blob: *.${config.mySystem.rootDomain};
        '';
      };
      nginx.virtualHosts.retrom-server = svc.mkNginxVHost {
        host = "retrom-server";
        proxyPass = "http://retrom.docker:5101";
        useAuthelia = false;
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "retrom" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "retrom";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-retrom = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        cp "${./config.json}" "${cfg.dataDir}/config/config.json"
        sed -i"" "s#@@DATABASE_URL@@#$(cat ${
          config.sops.secrets."${cfg.sopsSecretPrefix}/DATABASE_URL".path
        })#g" "${cfg.dataDir}/config/config.json"
        sed -i"" "s#@@IGDB_CLIENT_ID@@#$(cat ${
          config.sops.secrets."${cfg.sopsSecretPrefix}/IGDB_CLIENT_ID".path
        })#g" "${cfg.dataDir}/config/config.json"
        sed -i"" "s#@@IGDB_CLIENT_SECRET@@#$(cat ${
          config.sops.secrets."${cfg.sopsSecretPrefix}/IGDB_CLIENT_SECRET".path
        })#g" "${cfg.dataDir}/config/config.json"
        chown 1505:1505 "${cfg.dataDir}/config" "${cfg.dataDir}/config/config.json"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.RetROM = svc.mkHomepage "retrom" // {
        description = "Server for steam-like retro games manager";
      };
    };
  };
}
