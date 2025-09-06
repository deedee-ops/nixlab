{
  inputs,
  config,
  lib,
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
    enableCUDA = lib.mkEnableOption "NVIDIA CUDA";
    exposePort = lib.mkOption {
      type = lib.types.bool;
      description = "Expose ollama port, to be available outside of the machine.";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      inherit (cfg) loadModels;
      enable = true;
      user = "ollama";
      group = "ollama";

      package = inputs.nixpkgs-stable.legacyPackages.x86_64-linux.ollama;
    }
    // lib.optionalAttrs cfg.exposePort {
      host = "0.0.0.0";
    }
    // lib.optionalAttrs cfg.enableCUDA {
      acceleration = "cuda";
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
