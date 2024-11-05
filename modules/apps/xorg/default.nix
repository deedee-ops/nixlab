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

  config = lib.mkIf osConfig.mySystem.xorg.enable {
    stylix.targets.xresources.enable = true;

    home = {
      pointerCursor = {
        name = "catppuccin-mocha-dark-cursors";
        size = 48;
        package = pkgs.catppuccin-cursors.mochaDark;
        x11.enable = true;
        gtk.enable = true;
      };
    };

    fonts.fontconfig.enable = true;

    xresources = {
      path = "${config.xdg.configHome}/X11/xresources";
      properties = {
        "Xft.dpi" = 192;
      };
    };
  };
}
