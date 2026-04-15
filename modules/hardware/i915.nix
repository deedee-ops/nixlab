_: {
  flake.nixosModules.hardware-i915 =
    { pkgs, ... }:
    {
      config = {
        hardware.graphics = {
          enable = true;
          extraPackages = [
            pkgs.intel-media-driver
            pkgs.intel-vaapi-driver
            pkgs.libvdpau-va-gl
          ];
        };

        environment = {
          sessionVariables = {
            LIBVA_DRIVER_NAME = "iHD";
            LIBVA_DRIVERS_PATH = "${pkgs.intel-media-driver}/lib/dri/";
          };
          systemPackages = [
            pkgs.intel-gpu-tools
            pkgs.libva
            pkgs.libva-utils
          ];
        };
      };
    };
}
