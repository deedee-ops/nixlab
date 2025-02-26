{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.open-webui;
  image =
    if config.myHardware.nvidia.enable then
      "ghcr.io/open-webui/open-webui:cuda@sha256:72e3a276586471d5188fb9277d012eeefb91e3e47e971cbc8d98396590dadf36"
    else
      "ghcr.io/open-webui/open-webui:main@sha256:4450eb013528cbb49d8c4ea83602fb918be7dc01cabd492f8302184b78b793f2";
in
{
  options.mySystemApps.open-webui = {
    enable = lib.mkEnableOption "open-webui container";
    standalone = lib.mkEnableOption "standalone mode - exposes port directly, and disables nginx.";
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
        inherit image;
        environment = {
          WEBUI_AUTH = "False";
          OLLAMA_BASE_URL = "http://host.docker.internal:${builtins.toString config.services.ollama.port}";
        };
        ports = lib.optionals cfg.standalone [ "8080:8080" ];
        volumes = [ "${cfg.dataDir}/data:/app/backend/data" ];

        extraOptions = [
          "--cap-add=all"
        ];
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
          host = "ai";
          proxyPass = "http://open-webui.docker:8080";
        };
      };
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = lib.mkIf (!cfg.standalone) {
      services.Apps.open-webui = svc.mkHomepage "open-webui" // {
        description = "Front-end for AI models.";
      };
    };
  };
}
