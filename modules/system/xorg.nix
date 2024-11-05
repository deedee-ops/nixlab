{
  config,
  lib,
  pkgs,
  ...
}:
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
    sddmThemePackage = lib.mkOption {
      type = lib.types.package;
      description = "Theme package to use for SDDM.";
      default = pkgs.catppuccin-sddm-corners;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      displayManager.sddm = {
        enable = true;
        theme = cfg.sddmThemePackage.pname;
      };

      xserver = {
        enable = true;
        windowManager."${cfg.windowManager}".enable = true;
      };
    };

    environment.systemPackages = [
      cfg.sddmThemePackage
      # https://github.com/nix-community/home-manager/issues/3113
      pkgs.dconf
    ];
  };
}
