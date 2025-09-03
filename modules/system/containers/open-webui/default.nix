{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.open-webui;
in
{
  options.mySystemApps.open-webui = {
    enable = lib.mkEnableOption "open-webui container";
    standalone = lib.mkEnableOption "standalone mode - exposes port directly, and disables nginx.";
    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "Subdomain for ${config.mySystem.rootDomain}.";
      default = "open-webui";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/open-webui";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.mySystemApps.ollama.enable;
        message = "Open-WebUI needs ollama enabled.";
      }
    ];

    virtualisation.oci-containers.containers.open-webui = svc.mkContainer {
      cfg = {
        image = "ghcr.io/open-webui/open-webui:main@sha256:06f4cae7f8873ebcee7952d9993e457c1b083c6bea67b10bc356db7ac71c28e2";
        environment = {
          WEBUI_AUTH = "True";
          OLLAMA_BASE_URL = "http://host.docker.internal:${builtins.toString config.services.ollama.port}";
        };
        ports = lib.optionals cfg.standalone [ "8080:8080" ];
        volumes = [ "${cfg.dataDir}/data:/app/backend/data" ];

        extraOptions = [
          "--cap-add=all"
        ];
      }
      // lib.optionalAttrs config.myHardware.nvidia.enable {
        image = "ghcr.io/open-webui/open-webui:cuda@sha256:0e48f41dad86b08faacdce2d4b312bbd91b3007ab497c8eed87b215f88d931d0";
      };

      opts = {
        # scraping web results
        allowPublic = true;
        enableGPU = config.myHardware.nvidia.enable;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      ollama = {
        host = "0.0.0.0";
        openFirewall = true;
      };

      nginx = lib.mkIf (!cfg.standalone) {
        virtualHosts.open-webui = svc.mkNginxVHost {
          host = cfg.subdomain;
          proxyPass = "http://open-webui.docker:8080";
        };
      };
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = lib.mkIf (!cfg.standalone) {
      services.Apps.open-webui = svc.mkHomepage "open-webui" // {
        href = "https://${cfg.subdomain}.${config.mySystem.rootDomain}";
        description = "Front-end for AI models.";
      };
    };
  };
}
