{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.xorg;
in
{
  imports = [
    ./kiosk.nix
  ];

  options.mySystemApps.xorg = {
    enable = lib.mkEnableOption "xorg";
    autoLogin = lib.mkEnableOption "autologin for xorg";
    windowManager = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Window manager to use.";
      default = null;
    };
    sddmThemePackage = lib.mkOption {
      type = lib.types.package;
      description = "Theme package to use for SDDM.";
      default = pkgs.catppuccin-sddm-corners;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        sddm = {
          enable = true;
          theme = cfg.sddmThemePackage.pname;
        };
        autoLogin = lib.mkIf cfg.autoLogin {
          enable = true;
          user = config.mySystem.primaryUser;
        };
      };

      xserver =
        {
          enable = true;
        }
        // lib.optionalAttrs (cfg.windowManager != null) {
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
