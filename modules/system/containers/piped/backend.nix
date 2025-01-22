{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.piped;
  secretEnvs = [ "PIPED_DB_PASSWORD" ];
  configuration = svc.templateFile {
    name = "config.properties";
    src = ./config.properties;

    vars = {
      PIPED_DB_HOST = "host.docker.internal";
      PIPED_DB_DBNAME = "piped";
      PIPED_DB_USERNAME = "piped";
      ROOT_DOMAIN = config.mySystem.rootDomain;
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "piped-api";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "piped";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/PIPED_DB_PASSWORD".path;
        databases = [ "piped" ];
      }
    ];

    virtualisation.oci-containers.containers.piped-api = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/piped:latest@sha256:ce67543291ccc4579295ba8fe5c18efeea4c03c32474fd92bef2126b8dad40bb";
        volumes = [ "/run/piped/config.properties:/app/config.properties:ro" ];
      };
      opts = {
        # proxying to youtube
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.piped-api = svc.mkNginxVHost {
        host = "piped-api";
        proxyPass = "http://piped-api.docker:8080";
        useAuthelia = false;
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "piped" ]; };
    };

    systemd.services.docker-piped-api = {
      preStart = lib.mkAfter ''
        mkdir -p /run/piped
        sed "s,@@PIPED_DB_PASSWORD@@,$(cat ${
          config.sops.secrets."${cfg.sopsSecretPrefix}/PIPED_DB_PASSWORD".path
        }),g" ${configuration} > /run/piped/config.properties
      '';
    };
  };
}
