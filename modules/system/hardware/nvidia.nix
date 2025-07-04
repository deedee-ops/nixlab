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
    forceCompileCUDA = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Compile all applicable packages with CUDA support directly.
        WARNING! Since, there is no cache of these packages, nixos rebuild may take
        long, long, looooonggg time!
      '';
    };
    metamodes = lib.mkOption {
      type = lib.types.str;
      description = "XServer metamodes configuration for displays.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      blacklistedKernelModules = [ "nouveau" ]; # disable community nvidia driver

      # https://bbs.archlinux.org/viewtopic.php?id=294326
      # https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Preserve_video_memory_after_suspend
      kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    };

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

    # nvidia cards with old drivers my go haywire when device is put into sleep
    systemd.targets = lib.mkIf (config.hardware.nvidia.package.version < "570") {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };

    systemd.services.nvidia-autotune = lib.mkIf config.mySystem.powerSaveMode {
      description = "nVIDIA Auto-Tune";
      wantedBy = [ "multi-user.target" ];
      path = [
        config.hardware.nvidia.package
        pkgs.gawk
      ];
      serviceConfig = {
        Type = "oneshot";
      };

      script = ''
        nvidia-smi -pl "$(nvidia-smi -q -d POWER | grep 'Min Power Limit' | grep 'W$' | awk '{print $(NF-1)}')"
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
