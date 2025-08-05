{
  osConfig,
  lib,
  ...
}:
{
  config = lib.mkIf osConfig.mySystemApps.xorg.enable {
    qt = {
      enable = true;
      platformTheme.name = "gtk3"; # align with GTK
    };

    home = {
      sessionVariables = {
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      };
    };
  };
}
