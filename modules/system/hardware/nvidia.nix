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
    metamodes = lib.mkOption {
      type = lib.types.str;
      description = "XServer metamodes configuration for displays.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
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

    mySystem.allowUnfree = [
      "cuda-merged"
      "cuda_cccl"
      "cuda_cudart"
      "cuda_cuobjdump"
      "cuda_cupti"
      "cuda_cuxxfilt"
      "cuda_gdb"
      "cuda_nvcc"
      "cuda_nvdisasm"
      "cuda_nvml_dev"
      "cuda_nvprune"
      "cuda_nvrtc"
      "cuda_nvtx"
      "cuda_profiler_api"
      "cuda_sanitizer_api"
      "libcublas"
      "libcufft"
      "libcurand"
      "libcusolver"
      "libcusparse"
      "libnpp"
      "libnvjitlink"

      "nvidia-settings"
      "nvidia-x11"
    ];
  };
}
