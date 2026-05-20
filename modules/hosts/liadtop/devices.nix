_: {
  flake.nixosModules.hosts-liadtop-devices =
    { lib, pkgs, ... }:
    let
      lidAction = "suspend"; # suspend or suspend-then-hibernate
    in
    {
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
        graphics = {
          enable = true;
          extraPackages = [ pkgs.mesa ];
        };
        i2c.enable = true;
      };

      # mediatek bluetooth regression patch, waiting for it, to be merged upstream
      # more info: https://github.com/NixOS/nixpkgs/issues/521528
      boot.kernelPatches = [
        {
          name = "Bluetooth: btmtk: accept too short WMT FUNC_CTRL events";
          patch = pkgs.fetchurl {
            url = "https://git.kernel.org/pub/scm/linux/kernel/git/bluetooth/bluetooth-next.git/patch/?id=162b1adeb057d28ad84fd8a03f3c50cf08db5c62";
            hash = "sha256-ij0hQmC0U++AdXWQy6nycnDe6z4yaMoQIrSiLal5DHc=";
          };
        }
      ];

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
          InhibitDelayMaxSec = 10;
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
