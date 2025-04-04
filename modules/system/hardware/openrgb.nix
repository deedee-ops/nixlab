{
  config,
  lib,
  ...
}:
let
  cfg = config.myHardware.openrgb;
in
{
  options.myHardware.openrgb = {
    enable = lib.mkEnableOption "openrgb";
    profile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Path to profile which will be autoapplied on system start.";
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.hardware.openrgb.enable = true;
    boot.kernelParams = [ "acpi_enforce_resources=lax" ]; # g.skill RAM has problems when this is not set

    home-manager.users."${config.mySystem.primaryUser
    }".home.persistence."${config.mySystem.impermanence.persistPath}${
      config.home-manager.users."${config.mySystem.primaryUser}".home.homeDirectory
    }" =
      lib.mkIf config.mySystem.impermanence.enable {
        directories = [
          ".config/OpenRGB"
        ];
      };

    mySystemApps.xorg.userAutorun = {
      apply-openrgb-profile = "${lib.getExe config.services.hardware.openrgb.package} -p ${cfg.profile}";
    };
  };
}
