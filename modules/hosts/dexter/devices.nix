_: {
  flake.nixosModules.hosts-dexter-devices =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.ddcutil ];
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
        i2c.enable = true;
        graphics = {
          enable = true;
          extraPackages = [ pkgs.intel-media-driver ];
        };
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

      security.rtkit.enable = true;

      services = {
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          wireplumber = {
            enable = true;
            extraConfig = {
              "10-disable-hdmi" = {
                "monitor.alsa.rules" = [
                  {
                    matches = [ { "node.name" = "~alsa_output.*hdmi.*"; } ];
                    actions.update-props = {
                      "node.disabled" = true;
                    };
                  }
                ];
              };
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
                  "default.configured.audio.sink" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
                };
              };
            };
          };
        };
      };
    };
}
