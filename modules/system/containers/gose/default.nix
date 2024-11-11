{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.gose;
  secretEnvs = [
    "GOSE_ACCESS_KEY"
    "GOSE_SECRET_KEY"
    "GOSE_BUCKET"
  ];
in
{
  options.mySystemApps.gose = {
    enable = lib.mkEnableOption "gose container";
    s3Host = lib.mkOption {
      type = lib.types.str;
      description = "S3 hostname (without proto but with port if necessary).";
      example = "s3.example.com:9000";
      default = "s3.${config.mySystem.rootDomain}";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/gose/env";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "gose";
    };

    virtualisation.oci-containers.containers.gose = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/gose:latest@sha256:e2312775f37b9d4e66ca9bf886d91f7211a5a9d375f52fdebc30218c75238665";
        environment = {
          GOSE_BASE_URL = "https://files.${config.mySystem.rootDomain}";
          GOSE_ENDPOINT = cfg.s3Host;
          GOSE_REGION = "us-east-1";
          GOSE_PATH_STYLE = "true";
          GOSE_NO_SSL = "false";
          GOSE_SETUP_BUCKET = "false";
          GOSE_SETUP_CORS = "false";
          GOSE_SETUP_LIFECYCLE = "false";
        };
        extraOptions = lib.optionals (lib.strings.hasSuffix config.mySystem.rootDomain cfg.s3Host) [
          "--add-host=${cfg.s3Host}:${config.mySystemApps.docker.network.private.hostIP}"
        ];
        volumes = svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
        };
      };
    };

    services = {
      nginx.virtualHosts.gose = svc.mkNginxVHost {
        host = "files";
        proxyPass = "http://gose.docker:8080";
        useAuthelia = false;
      };
    };

    mySystemApps.homepage = {
      services.Apps."GoSƐ" = svc.mkHomepage "gose" // {
        icon = "https://cdn.jsdelivr.net/gh/stv0g/gose@main/frontend/img/gose-logo.svg";
        href = "https://files.${config.mySystem.rootDomain}";
        description = "A terascale file uploader";
      };
    };
  };
}
