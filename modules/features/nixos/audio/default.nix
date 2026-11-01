_: {
  flake.nixosModules.features-nixos-audio =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.nixos.audio;
    in
    {
      options.features.nixos.audio = {
        defaultSink = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = ''
            Node name of the preferred ALSA audio sink: it wins over every other ALSA sink, but a connected Bluetooth
            headset still takes over, and a sink picked by hand overrides both. To list them use: `wpctl status -n`
          '';
          default = null;
          example = "alsa_output.pci-0000_00_1f.3.analog-stereo";
        };
        defaultSource = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = ''
            Node name of the preferred ALSA audio source, same rules as `defaultSink`.
            To list them use: `wpctl status -n`
          '';
          default = null;
          example = "alsa_input.pci-0000_00_1f.3.analog-stereo";
        };
        headsetModePackage = lib.mkOption {
          type = lib.types.package;
          description = "`bt-headset-mode` script switching Bluetooth headsets between music and call profiles.";
          readOnly = true;
          default = pkgs.writeShellApplication {
            name = "bt-headset-mode";
            runtimeInputs = [
              pkgs.jq
              pkgs.libnotify
              pkgs.pulseaudio
            ];
            text = builtins.readFile ./bt-headset-mode.sh;
          };
        };
        callModeIdleTimeout = lib.mkOption {
          type = lib.types.ints.unsigned;
          description = ''
            Seconds without any app recording from a Bluetooth headset in call mode, after which it is switched back
            to music mode. 0 disables it.
          '';
          default = 0;
        };
      };

      config = {
        environment.systemPackages = [ cfg.headsetModePackage ];

        systemd.user.services.bt-headset-mode = lib.mkIf (cfg.callModeIdleTimeout > 0) {
          description = "Switch Bluetooth headsets back to music mode after calls";
          after = [ "wireplumber.service" ];
          wantedBy = [ "default.target" ];
          serviceConfig = {
            ExecStart = "${lib.getExe cfg.headsetModePackage} watch ${toString cfg.callModeIdleTimeout}";
            Restart = "always";
            RestartSec = 5;
          };
        };

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
                  # Autoswitch flips headsets to call mode when an app opens the mic and back 2s after it closes
                  # it. Teams drops the mic briefly after the switch and never reopens it, leaving a silent call.
                  # Call mode is switched by hand with bt-headset-mode instead (niri: Mod+B).
                  "wireplumber.settings"."bluetooth.autoswitch-to-headset-profile" = false;
                  "monitor.bluez.rules" = [
                    {
                      matches = [ { "device.name" = "~bluez_card.*"; } ];
                      actions.update-props = {
                        "bluez5.auto-connect" = "[ hfp_hf hsp_hs a2dp_sink ]";
                      };
                    }
                  ];
                };
              }
              // lib.optionalAttrs (cfg.defaultSink != null || cfg.defaultSource != null) {
                # WirePlumber 0.5 keeps configured defaults only in its state file, so prefer the nodes by
                # priority.session instead: other ALSA nodes go below the preferred one, which stays below
                # Bluetooth (1010 sinks, 2010 sources). Rules apply in order, the last match wins.
                "50-default-nodes" = {
                  "monitor.alsa.rules" =
                    let
                      prefer = prefix: name: base: [
                        {
                          matches = [ { "node.name" = "~${prefix}.*"; } ];
                          actions.update-props."priority.session" = base - 100;
                        }
                        {
                          matches = [ { "node.name" = name; } ];
                          actions.update-props."priority.session" = base;
                        }
                      ];
                    in
                    lib.optionals (cfg.defaultSink != null) (prefer "alsa_output" cfg.defaultSink 1000)
                    ++ lib.optionals (cfg.defaultSource != null) (prefer "alsa_input" cfg.defaultSource 2000);
                };
              };
            };
          };
        };
      };
    };
}
