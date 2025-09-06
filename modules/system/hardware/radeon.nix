{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHardware.radeon;
in
{
  options.myHardware.radeon = {
    enable = lib.mkEnableOption "radeon";
    forceCompileROCM = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Compile all applicable packages with ROCM support directly.
        WARNING! Since, there is no cache of these packages, nixos rebuild may take
        long, long, looooonggg time!
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;

        extraPackages = [
          pkgs.rocmPackages.clr
          pkgs.rocmPackages.clr.icd
          pkgs.rocmPackages.rocm-runtime
          pkgs.rocmPackages.rocminfo
        ];
      };
    };

    environment.systemPackages = [
      pkgs.clinfo
      pkgs.libva
      pkgs.libva-utils
      pkgs.libvdpau-va-gl
      pkgs.vaapiVdpau
    ];

    services.xserver.videoDrivers = [ "amdgpu" ];

    # This is necesery because many programs hard-code the path to hip
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  };
}
