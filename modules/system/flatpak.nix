{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem;
in
{
  options.mySystem = {
    flatpakEnable = lib.mkEnableOption "flatpak";
  };

  config = lib.mkIf cfg.flatpakEnable {
    services.flatpak = {
      enable = true;
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ "/var/lib/flatpak" ]; };
  };
}
