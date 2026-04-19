_: {
  flake.nixosModules.hosts-liadtop-devices =
    { lib, ... }:
    let
      lidAction = "suspend"; # suspend or suspend-then-hibernate
    in
    {
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
        i2c.enable = true;
      };

      networking = {
        networkmanager.enable = true;
        hostName = "liadtop";
      };

      security.rtkit.enable = true;

      boot.kernelParams = [ "resume=/dev/disk/by-partlabel/disk-system-swap" ];

      systemd.sleep.settings.Sleep = lib.optionalAttrs (lidAction == "suspend-then-hibernate") {
        AllowSuspendThenHibernate = "yes";
        HibernateDelaySec = "30min";
      };

      services = {
        logind.settings.Login = {
          HandleLidSwitch = lidAction;
          HandleLidSwitchDocked = "ignore";
          HandleLidSwitchExternalPower = lidAction;
          HandlePowerKey = lidAction;
          HandlePowerKeyLongPress = "poweroff";
        };

        upower.enable = true;

        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          wireplumber = {
            enable = true;
            extraConfig = {
              "20-bluetooth" = {
                "monitor.bluez.rules" = [
                  {
                    matches = [ { "device.name" = "~bluez_card.*"; } ];
                    actions.update-props = {
                      "bluez5.auto-connect" = "[a2dp_sink a2dp_source]";
                    };
                  }
                ];
              };
              "50-default-sink" = {
                "wireplumber.settings" = {
                  "default.configured.audio.sink" = "alsa_output.pci-0000_04_00.6.HiFi__Speaker__sink";
                  "default.configured.audio.source" = "alsa_input.pci-0000_04_00.6.HiFi__Mic1__source";
                };
              };
            };
          };
        };
      };
    };
}
