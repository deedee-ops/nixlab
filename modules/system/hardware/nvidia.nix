{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHardware.nvidia;
in
{
  options.myHardware.nvidia = {
    enable = lib.mkEnableOption "nvidia";
    useOpenDrivers = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use NVIDIA open-source drivers - should be set true for all Turing, Ampere and newer architectures
        (effectively for RTX 2xxx and newer). If unsure, check compatible GPU list here:
        <https://github.com/NVIDIA/open-gpu-kernel-modules?tab=readme-ov-file#compatible-gpus>
      '';
    };
    metamodes = lib.mkOption {
      type = lib.types.str;
      description = "XServer metamodes configuration for displays.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.blacklistedKernelModules = [ "nouveau" ]; # disable community nvidia driver

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = cfg.useOpenDrivers;
        nvidiaSettings = true;
        # package = config.boot.kernelPackages.nvidiaPackages.stable;
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          # 570.124.04 fails during boot for some reason
          version = "570.133.07";
          sha256_64bit = "sha256-LUPmTFgb5e9VTemIixqpADfvbUX1QoTT2dztwI3E3CY=";
          openSha256 = "sha256-9l8N83Spj0MccA8+8R1uqiXBS0Ag4JrLPjrU3TaXHnM=";
          settingsSha256 = "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU=";
          usePersistenced = false;
        };
      };
    };

    environment.systemPackages = [
      pkgs.libva-utils
      pkgs.libva
      pkgs.nvidia-vaapi-driver
    ];

    services.xserver = {
      videoDrivers = [ "nvidia" ];
      screenSection = ''
        Option         "ForceFullCompositionPipeline" "on"
        Option         "AllowIndirectGLXProtocol" "off"
        Option         "TripleBuffer" "on"
        Option         "metamodes" "${cfg.metamodes}"
      '';
    };

    mySystem.allowUnfree =
      [
        "cuda_cccl"
        "cuda_cudart"
        "cuda_nvcc"
        "libcublas"
        "libcufft"
        "libnpp"

        "nvidia-settings"
        "nvidia-x11"
      ]
      ++ lib.optionals (!cfg.useOpenDrivers) [
        "cuda-merged"
        "cuda_cuobjdump"
        "cuda_cupti"
        "cuda_cuxxfilt"
        "cuda_gdb"
        "cuda_nvdisasm"
        "cuda_nvml_dev"
        "cuda_nvprune"
        "cuda_nvrtc"
        "cuda_nvtx"
        "cuda_profiler_api"
        "cuda_sanitizer_api"
        "libcurand"
        "libcusolver"
        "libcusparse"
        "libnvjitlink"
      ];
  };
}
