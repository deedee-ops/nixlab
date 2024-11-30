{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
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
  };

  config = lib.mkIf osConfig.mySystemApps.xorg.enable {
    stylix.targets.xresources.enable = true;

    fonts.fontconfig.enable = true;

    xsession.enable = true;
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
