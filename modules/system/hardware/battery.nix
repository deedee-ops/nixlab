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
    kernelModule = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Kernel module reponsible for handling battery.";
      default = null;
    };
    chargeLimit = lib.mkOption {
      type = lib.types.submodule {
        options = {
          top = lib.mkOption {
            type = lib.types.int;
            description = "Upper percentage limit to which battery will be charged.";
            default = 100;
          };
          bottom = lib.mkOption {
            type = lib.types.int;
            description = "Lower percentage limit to which battery will be charged.";
            default = 0;
          };
        };
      };
      default = {
        top = 100;
        bottom = 0;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules =
      let
        batteryLowScript = pkgs.writeShellScriptBin "battery-low.sh" ''
          PATH="${
            lib.makeBinPath [
              pkgs.coreutils
              pkgs.gawk
              pkgs.gnugrep
              pkgs.gnused
              pkgs.libnotify
              pkgs.sudo
              pkgs.systemd
            ]
          }:$PATH"

          # udev events are so fast, that /sys files may not catch up - so give them a second
          sleep 1

          if [ ! -f /tmp/.battery-ignore ] && [ "$(cat /sys/class/power_supply/BAT?/status)" = "Discharging" ]; then
            display=":$(ls --color=never /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"
            user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)
            uid=$(id -u $user)

            if [ ! -f /tmp/.battery-will-hibernate ] && [ "$(cat /sys/class/power_supply/BAT?/capacity)" -lt ${builtins.toString (cfg.chargeLimit.bottom + 5)} ]; then
              /run/wrappers/bin/sudo -u "$user" DISPLAY="$display" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" notify-send -u critical "Battery level low, will hibernate soon."
              touch /tmp/.battery-will-hibernate
            fi

            if [ "$(cat /sys/class/power_supply/BAT?/capacity)" -lt ${builtins.toString cfg.chargeLimit.bottom} ]; then
              if ! systemctl hibernate; then
                sudo -u "$user" DISPLAY="$display" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" notify-send -u critical "Battery below ${builtins.toString cfg.chargeLimit.bottom}% but failed to hibernate"
              fi
            fi
          else
            rm -f /tmp/.battery-will-hibernate
          fi

        '';
      in
      ''
        SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", RUN+="${lib.getExe batteryLowScript}"
      ''
      + (lib.optionalString (cfg.kernelModule != null) ''
        ACTION=="add", KERNEL=="${cfg.kernelModule}", RUN+="${pkgs.bash}/bin/bash -c 'echo ${builtins.toString cfg.chargeLimit.top} > /sys/class/power_supply/BAT?/charge_control_end_threshold'"
      '');

    home-manager.users."${config.mySystem.primaryUser}".myHomeApps = {
      awesome.showBattery = true;
      btop.showBattery = true;
    };
  };
}
