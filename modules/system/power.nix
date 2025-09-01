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
    powerSaveMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Switch to power save mode - should reduce power usage, in exchange of performance.";
    };
    powerUSBWhitelist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "USB Keyboard"
        "2.4G Receiver"
      ];
      description = ''
        List of USB device names to whitelist from autosuspend.
        You can list all availables ones using cat /sys/bus/usb/devices/*/product
      '';
    };
  };
  config = {
    services.logind.settings.Login =
      if ((config.systemd.targets ? suspend) && !config.systemd.targets.suspend.enable) then
        {
          HandlePowerKey = "poweroff";
          IdleAction = "poweroff";
          IdleActionSec = "5m";
        }
      else
        {
          HandlePowerKey = "suspend";
          IdleAction = "suspend";
          IdleActionSec = "5m";
        };
  }
  // (lib.mkIf cfg.powerSaveMode {
    powerManagement.enable = true;

    services.tlp = {
      enable = true;

      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        NMI_WATCHDOG = 0;
      };
    };

    systemd.services.powertop-autotune = {
      description = "Powertop Auto-Tune";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };

      script = ''
        ${pkgs.powertop}/bin/powertop --auto-tune || true
        sleep 2

      ''
      + (builtins.concatStringsSep "\n" (
        builtins.map (device: ''
          DEVICE="$(basename "$(dirname "$(grep -rl "${device}" /sys/bus/usb/devices/*/product)")")"
          if [ "$DEVICE" != "." ]; then
            echo 'on' > "/sys/bus/usb/devices/$DEVICE/power/control"
          fi
        '') cfg.powerUSBWhitelist
      ));
    };
  });
}
