{ config, lib, ... }:
let
  cfg = config.mySystem.xorg;
in
{
  options.mySystem.xorg = {
    enable = lib.mkEnableOption "xorg";
    windowManager = lib.mkOption {
      type = lib.types.str;
      description = "Window manager to use.";
      default = "awesome";
    };
    sddmTheme = lib.mkOption {
      type = lib.types.package;
      description = "Theme package to use for SDDM.";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      displayManager.sddm = {
        enable = true;
        theme = cfg.package.pname;
      };

      xserver = {
        enable = true;
        windowManager."${cfg.windowManager}".enable = true;
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
