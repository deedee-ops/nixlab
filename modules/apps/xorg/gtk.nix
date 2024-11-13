{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.mySystemApps.xorg.enable {
    stylix.targets.gtk.enable = true;

    gtk = {
      gtk2 = {
        configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      };
      cursorTheme = {
        package = pkgs.catppuccin-cursors.mochaDark;
        name = "catppuccin-mocha-dark-cursors";
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "blue";
        };
      };
    };
  };
}
