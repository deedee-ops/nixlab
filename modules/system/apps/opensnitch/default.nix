{ config, lib, ... }:
let
  cfg = config.mySystemApps.opensnitch;
in
{
  options.mySystemApps.opensnitch = {
    enable = lib.mkEnableOption "opensnitch app";
  };

  config = lib.mkIf cfg.enable {
    services.opensnitch.enable = true;

    home-manager.users."${config.mySystem.primaryUser}".services.opensnitch-ui.enable = true;
  };
}
