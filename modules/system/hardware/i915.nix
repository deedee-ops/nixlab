{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHardware.i915;
  libvaConfig = {
    LIBVA_DRIVER_NAME = "iHD";
    LIBVA_DRIVERS_PATH = "${pkgs.intel-media-driver}/lib/dri/";
  };
in
{
  options.myHardware.i915 = {
    enable = lib.mkEnableOption "i915";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      extraPackages = [
        pkgs.intel-media-driver
        pkgs.intel-vaapi-driver
        pkgs.libvdpau-va-gl
      ];
    };

    environment = {
      sessionVariables = libvaConfig;
      systemPackages = [ pkgs.intel-gpu-tools ];
    };

    home-manager.users."${config.mySystem.primaryUser}".home.sessionVariables = libvaConfig;
  };
}
