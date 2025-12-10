{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.comfyui;
in
{
  options.mySystemApps.comfyui = {
    enable = lib.mkEnableOption "comfyui container";
    standalone = lib.mkEnableOption "standalone mode - exposes port directly, and disables nginx.";
    subdomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Subdomain for ${config.mySystem.rootDomain}. Disables reverse proxy if null.";
      default = null;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/comfyui";
    };
    models = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Map of destination paths to URLs of models.";
      example = {
        "checkpoints/flux1-schnell-fp8.safetensors" =
          "https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors?download=true";
        "vae/ae.safetensors" =
          "https://huggingface.co/black-forest-labs/FLUX.1-schnell/blob/main/ae.safetensors?download=true";
        "clip/clip_l.safetensors" =
          "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true";
        "clip/t5xxl_fp8_e4m3fn.safetensors" =
          "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors?download=true";
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.comfyui = svc.mkContainer {
      cfg = {
        image = "ghcr.io/ajgon/comfyui:v0.4.0@sha256:d4725f1c3383126068a1ce5a3e34ddd60341a65b99e6d5b32747c4d51b9a044a";
        environment = {
          NVIDIA_VISIBLE_DEVICES = "all";
        };
        ports = lib.optionals cfg.standalone [ "8188:8188" ];
        volumes = [
          "${cfg.dataDir}/custom-nodes:/app/ComfyUI/custom_nodes"
          "${cfg.dataDir}/models:/app/ComfyUI/models"
          "${cfg.dataDir}/output:/app/ComfyUI/output"
          "${cfg.dataDir}/settings:/app/ComfyUI/user/default"
        ];

        extraOptions = [
          "--cap-add=all"
        ];
      };

      opts = {
        # downloading nodes and models
        allowPublic = true;
        enableGPU = config.myHardware.nvidia.enable;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx = lib.mkIf (!cfg.standalone && cfg.subdomain != null) {
        virtualHosts.comfyui = svc.mkNginxVHost {
          host = cfg.subdomain;
          proxyPass = "http://comfyui.docker:8188";
          customCSP = "disable";
          extraConfig = ''
            proxy_read_timeout 3600s;
          '';
        };
      };
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = lib.mkIf (!cfg.standalone && cfg.subdomain != null) {
      services.Apps.ComfyUI = svc.mkHomepage "comfyui" // {
        href = "https://${cfg.subdomain}.${config.mySystem.rootDomain}";
        description = "AI Image generation tool.";
      };
    };

    systemd.services.docker-comfyui = {
      preStart = lib.mkAfter (
        ''
          mkdir -p "${cfg.dataDir}/custom-nodes" "${cfg.dataDir}/models" "${cfg.dataDir}/output" "${cfg.dataDir}/settings"
          chown 1000:1000 "${cfg.dataDir}" "${cfg.dataDir}/custom-nodes" "${cfg.dataDir}/models" "${cfg.dataDir}/output" "${cfg.dataDir}/settings"
        ''
        + builtins.concatStringsSep "\n" (
          builtins.map (path: ''
            mkdir -p "${cfg.dataDir}/models/$(dirname "${path}")"
            [ ! -f "${cfg.dataDir}/models/${path}" ] && ${lib.getExe pkgs.curl} -L -o "${cfg.dataDir}/models/${path}" "${builtins.getAttr path cfg.models}"
            chown 1000:1000 "${cfg.dataDir}/models/$(dirname "${path}")" "${cfg.dataDir}/models/${path}"
          '') (builtins.attrNames cfg.models)
        )
      );
    };
  };
}
