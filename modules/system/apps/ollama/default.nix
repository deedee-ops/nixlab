{
  config,
  lib,
  pkgs-stable,
  ...
}:
let
  cfg = config.mySystemApps.ollama;
in
{
  options.mySystemApps.ollama = {
    enable = lib.mkEnableOption "ollama";
    loadModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of models to download on start.";
      default = [ ];
    };
    enableCUDA = lib.mkEnableOption "NVIDIA CUDA" // {
      default = config.myHardware.nvidia.enable && config.myHardware.nvidia.forceCompileCUDA;
    };
    enableROCM = lib.mkEnableOption "AMD ROCM" // {
      default = config.myHardware.radeon.enable && config.myHardware.radeon.forceCompileROCM;
    };
    exposePort = lib.mkOption {
      type = lib.types.bool;
      description = "Expose ollama port, to be available outside of the machine.";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.enableCUDA && cfg.enableROCM);
        message = "CUDA and ROCM cannot be enabled at the same time.";
      }
    ];

    services.ollama = {
      inherit (cfg) loadModels;
      enable = true;
      user = "ollama";
      group = "ollama";

      package = pkgs-stable.ollama;
    }
    // lib.optionalAttrs cfg.exposePort {
      host = "0.0.0.0";
    }
    // lib.optionalAttrs cfg.enableCUDA {
      acceleration = "cuda";
    }
    // lib.optionalAttrs cfg.enableROCM {
      acceleration = "rocm";
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              inherit (config.services.ollama) user group;
              directory = config.services.ollama.home;
              mode = "750";
            }
          ];
        };

    systemd.services.ollama.serviceConfig = lib.optionalAttrs config.mySystem.impermanence.enable {
      StateDirectory = lib.mkForce "";
    };

    mySystem.allowUnfree = [
      "cudnn"
    ];

    networking.firewall.allowedTCPPorts = lib.optionals cfg.exposePort [ 11434 ];
  };
}
