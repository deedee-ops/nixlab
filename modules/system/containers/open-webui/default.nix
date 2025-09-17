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
    generateImages = lib.mkEnableOption "generate images via stable diffusion";
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

    mySystemApps.comfyui = lib.optionalAttrs cfg.generateImages {
      enable = true;
      models = {
        "checkpoints/flux1-schnell-fp8.safetensors" =
          "https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors?download=true";
        "vae/ae.safetensors" =
          "https://huggingface.co/black-forest-labs/FLUX.1-schnell/blob/main/ae.safetensors?download=true";
        "clip/clip_l.safetensors" =
          "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true";
        "clip/t5xxl_fp8_e4m3fn.safetensors" =
          "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors?download=true";
      };
    };

    virtualisation.oci-containers.containers.open-webui = svc.mkContainer {
      cfg = {
        image = "ghcr.io/open-webui/open-webui:main@sha256:8a27cb1dbd6e3f81381fa03525be778620aa7f675704557f96fd183dc095ddc5";
        environment = {
          WEBUI_AUTH = "True";
          OLLAMA_BASE_URL = "http://host.docker.internal:${builtins.toString config.services.ollama.port}";
        }
        // lib.optionalAttrs cfg.generateImages {
          ENABLE_IMAGE_GENERATION = "True";
          COMFYUI_BASE_URL = "http://comfyui:8188";
        };
        ports = lib.optionals cfg.standalone [ "8080:8080" ];
        volumes = [ "${cfg.dataDir}/data:/app/backend/data" ];

        extraOptions = [
          "--cap-add=all"
        ];
      }
      // lib.optionalAttrs config.myHardware.nvidia.enable {
        image = "ghcr.io/open-webui/open-webui:cuda@sha256:e353f7ebc07bf7c3c2ee0c52b77bbd59ddc346b93046289f0e44c75f9855b6f8";
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
          extraConfig = ''
            proxy_read_timeout 3600s;
          '';
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
