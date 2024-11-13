{ osConfig, lib, ... }:
{
  config = lib.mkIf osConfig.mySystemApps.xorg.enable {
    services.picom = {
      enable = true;

      fade = false;
      shadow = false;
      backend = "xrender";
      vSync = false;

      settings = {
        "blur-background" = false;
        "corner-radius" = 0;
        "unredir-if-possible" = false;
        "use-ewmh-active-win" = true;
      };
    };
  };
}
