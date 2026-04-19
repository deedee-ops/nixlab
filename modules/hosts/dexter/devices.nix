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
