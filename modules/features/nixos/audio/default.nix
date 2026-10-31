_: {
  flake.nixosModules.features-nixos-audio =
    { config, lib, ... }:
    let
      cfg = config.features.nixos.audio;
    in
    {
      options.features.nixos.audio = {
        defaultSink = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "Node name of the default audio sink. To list them use: `wpctl status -n`";
          default = null;
          example = "alsa_output.pci-0000_00_1f.3.analog-stereo";
        };
        defaultSource = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "Node name of the default audio source. To list them use: `wpctl status -n`";
          default = null;
          example = "alsa_input.pci-0000_00_1f.3.analog-stereo";
        };
      };

      config = {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
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
              }
              // lib.optionalAttrs (cfg.defaultSink != null || cfg.defaultSource != null) {
                "50-default-sink" = {
                  "wireplumber.settings" =
                    lib.optionalAttrs (cfg.defaultSink != null) {
                      "default.configured.audio.sink" = cfg.defaultSink;
                    }
                    // lib.optionalAttrs (cfg.defaultSource != null) {
                      "default.configured.audio.source" = cfg.defaultSource;
                    };
                };
              };
            };
          };
        };
      };
    };
}
