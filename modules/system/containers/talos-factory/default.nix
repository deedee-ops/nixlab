{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.talos-factory;
in
{
  options.mySystemApps.talos-factory = {
    enable = lib.mkEnableOption "talos-factory container";
    internalRegistryHost = lib.mkOption {
      type = lib.types.str;
      description = "Host of docker registry storing factory images - host available internally.";
      example = "registry:5000";
    };
    externalRegistryHost = lib.mkOption {
      type = lib.types.str;
      description = "Host of docker registry storing factory images - host available for outside world.";
      example = "registry.example.com";
    };
    signingKeysSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing all factory signing key files.";
      default = "system/apps/talos-factory/keys";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "${cfg.signingKeysSopsSecret}/cache-signing-key.key" = { };
      "${cfg.signingKeysSopsSecret}/pcr-signing-key.pem" = { };
      "${cfg.signingKeysSopsSecret}/uki-signing-cert.pem" = { };
      "${cfg.signingKeysSopsSecret}/uki-signing-key.pem" = { };
    };

    virtualisation.oci-containers.containers.talos-factory = svc.mkContainer {
      cfg = {
        image = "ghcr.io/siderolabs/image-factory:v1.0.2@sha256:d310951b03f8dec2db757547d3fc931d8d91279d05b2c327ce2768c19b387c4b";
        cmd = [
          "-external-url"
          "https://factory.${config.mySystem.rootDomain}"
          "-cache-signing-key-path"
          "/config/cache-signing-key.key"
          "-secureboot"
          "-secureboot-pcr-key-path"
          "/config/pcr-signing-key.pem"
          "-secureboot-signing-cert-path"
          "/config/uki-signing-cert.pem"
          "-secureboot-signing-key-path"
          "/config/uki-signing-key.pem"
          "-insecure-schematic-service-repository"
          "-schematic-service-repository"
          "${cfg.internalRegistryHost}/talos/schematic"
          "-insecure-installer-internal-repository"
          "-installer-internal-repository"
          "${cfg.internalRegistryHost}/talos/images"
          "-installer-external-repository"
          "${cfg.externalRegistryHost}/talos/images"
          "-insecure-cache-repository"
          "-cache-repository"
          "${cfg.internalRegistryHost}/talos/cache"
        ];
        volumes = [
          "${
            config.sops.secrets."${cfg.signingKeysSopsSecret}/cache-signing-key.key".path
          }:/config/cache-signing-key.key"
          "${
            config.sops.secrets."${cfg.signingKeysSopsSecret}/pcr-signing-key.pem".path
          }:/config/pcr-signing-key.pem"
          "${
            config.sops.secrets."${cfg.signingKeysSopsSecret}/uki-signing-cert.pem".path
          }:/config/uki-signing-cert.pem"
          "${
            config.sops.secrets."${cfg.signingKeysSopsSecret}/uki-signing-key.pem".path
          }:/config/uki-signing-key.pem"
        ];
      };
      opts = {
        # access to external registries
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.talos-factory = svc.mkNginxVHost {
        host = "factory";
        proxyPass = "http://talos-factory.docker:8080";
        useAuthelia = false;
      };
    };

    mySystemApps.homepage = {
      services.Apps."Talos Factory" = svc.mkHomepage "factory" // {
        description = "Talos images factory";
      };
    };
  };
}
