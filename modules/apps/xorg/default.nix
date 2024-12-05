{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.xorg;
in
{
  imports = [
    ./autorandr.nix
    ./gtk.nix
    ./picom.nix
    ./qt.nix
  ];

  options.myHomeApps.xorg = {
    terminal = lib.mkOption {
      type = lib.types.package;
      description = "Default terminal package.";
      default = pkgs.alacritty;
    };
    trackpadSupport = lib.mkEnableOption "trackpad support";
  };

  config = lib.mkIf osConfig.mySystemApps.xorg.enable {
    stylix.targets.xresources.enable = true;

    fonts.fontconfig.enable = true;

    xsession =
      {
        enable = true;
      }
      // lib.optionalAttrs cfg.trackpadSupport {
        initExtra = ''
          ${lib.getExe pkgs.libinput-three-finger-drag} &
        '';
      };
    xdg.mimeApps.enable = true;

    xresources = {
      path = "${config.xdg.configHome}/X11/xresources";
      properties = {
        "Xft.dpi" = 192;
      };
    };

    home = {
      packages = [
        pkgs.roboto
        pkgs.xclip # pbcopy and pbpaste
      ];

      sessionVariables = {
        XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
      };
    };
  };
}
