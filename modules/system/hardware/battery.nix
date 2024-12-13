{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHardware.battery;
in
{
  options.myHardware.battery = {
    enable = lib.mkEnableOption "battery";
    chargeUpperLimit = lib.mkOption {
      type = lib.types.int;
      description = "Upper percentage limit to which battery will be charged.";
      default = 100;
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      ACTION=="add", KERNEL=="asus-nb-wmi", RUN+="${pkgs.bash}/bin/bash -c 'echo ${builtins.toString cfg.chargeUpperLimit} > /sys/class/power_supply/BAT?/charge_control_end_threshold'"
    '';

    home-manager.users."${config.mySystem.primaryUser}".myHomeApps = {
      awesome.showBattery = true;
      btop.showBattery = true;
    };
  };
}
