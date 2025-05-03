{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.registry;
in
{
  options.mySystemApps.registry = {
    enable = lib.mkEnableOption "registry container";
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing registry envs.";
      default = "system/apps/registry/envfile";
    };
    s3 = lib.mkOption {
      type = lib.types.submodule {
        options = {
          endpoint = lib.mkOption {
            type = lib.types.str;
          };
          region = lib.mkOption {
            type = lib.types.str;
            default = "us-east-1";
          };
          bucket = lib.mkOption {
            type = lib.types.str;
            default = "registry";
          };
          encrypt = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          secure = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
        };
      };
      default = {
        region = "us-east-1";
        bucket = "registry";
        encrypt = false;
        secure = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.registry = svc.mkContainer {
      cfg = {
        image = "public.ecr.aws/docker/library/registry:3.0.0@sha256:1fc7de654f2ac1247f0b67e8a459e273b0993be7d2beda1f3f56fbf1001ed3e7";
        user = "65000:65000";
        environment = {
          OTEL_TRACES_EXPORTER = "none";
          REGISTRY_LOG_LEVEL = "info";
          REGISTRY_STORAGE = "s3";
          REGISTRY_STORAGE_S3_BUCKET = cfg.s3.bucket;
          REGISTRY_STORAGE_S3_CHUNKSIZE = "5242880";
          REGISTRY_STORAGE_S3_ENCRYPT = if cfg.s3.encrypt then "true" else "false";
          REGISTRY_STORAGE_S3_FORCEPATHSTYLE = "true";
          REGISTRY_STORAGE_S3_REGION = cfg.s3.region;
          REGISTRY_STORAGE_S3_REGIONENDPOINT = cfg.s3.endpoint;
          REGISTRY_STORAGE_S3_ROOTDIRECTORY = "/";
          REGISTRY_STORAGE_S3_SECURE = if cfg.s3.secure then "true" else "false";
          REGISTRY_STORAGE_S3_V4AUTH = "true";
        };
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
      };
      opts = {
        # access S3
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.registry = svc.mkNginxVHost {
        host = "registry";
        proxyPass = "http://registry.docker:5000";
        useAuthelia = false;
      };
    };
  };
}
