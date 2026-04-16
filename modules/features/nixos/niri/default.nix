{
  self,
  inputs,
  lib,
  ...
}:
let
  niriOptions = {
    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        List of monitors detected and expected to be supported by niri.
        To determine them use: `niri msg outputs`
      '';
      default = [ "default" ]; # for one monitor whole logic will be ignored
      example = [
        "DP-1"
        "HDMI-A-1"
      ];
    };

    terminal = lib.mkOption {
      type = lib.types.enum [ "ghostty" ];
      description = "Default terminal emulator to use";
      default = "ghostty";
    };

    noctaliaShellExtraSettings = lib.mkOption {
      type = lib.types.attrs;
      description = "Noctalia shell extra settings to be merged with defaults";
      default = { };
    };
  };
in
{
  flake.nixosModules.features-nixos-niri =
    {
      config,
      pkgs,
      ...
    }:
    {
      options.features.nixos.niri = niriOptions;

      config = {
        # services.greetd = {
        #   enable = true;
        #   settings = {
        #     default_session = {
        #       command = "niri-session";
        #       user = "ajgon";
        #     };
        #   };
        # };

        services.logind.settings.Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "suspend";
        };
        # security.pam.services.swaylock = { };

        programs.niri = {
          enable = true;

          package = inputs.wrapper-modules.wrappers.niri.wrap (
            {
              inherit pkgs;
              imports = [ self.wrapperModules.niri ];
            }
            // config.features.nixos.niri
          );
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        imports = [ self.wrapperModules.niri ];

        extraPackages = [
          pkgs.brightnessctl
          # pkgs.procps
          # pkgs.swayidle
          # pkgs.swaylock
          pkgs.swayosd
        ];
      };
    };

  flake.wrapperModules.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options = niriOptions;

      config = {
        v2-settings = true;

        settings =
          let
            workspaces = map (w: "w${toString w}") (builtins.genList (x: x) 10);
            niriSwitchWs = pkgs.writeShellApplication {
              name = "niri-switch-ws.sh";
              runtimeInputs = [
                pkgs.jq
                pkgs.niri
              ];
              text = builtins.readFile ./niri-switch-ws.sh;
            };
            noctaliaShellPkg = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
              inherit pkgs;
              settings = lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings config.noctaliaShellExtraSettings;
            };
          in
          {
            prefer-no-csd = _: { };
            screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d-%H%M%S_scrot.png";
            hotkey-overlay.skip-at-startup = _: { };
            gestures.hot-corners.off = _: { };

            environment = {
              DISPLAY = ":0"; # for xwayland-satellite
              MOZ_ENABLE_WAYLAND = "1";
              QT_QPA_PLATFORM = "wayland";
              QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
              XDG_CURRENT_DESKTOP = "niri";
              XDG_SESSION_TYPE = "wayland";
            };

            cursor = {
              xcursor-size = 24;
              hide-after-inactive-ms = 3000;
            };

            input = {
              focus-follows-mouse = _: {
                props = {
                  max-scroll-amount = "95%";
                };
              };
              workspace-auto-back-and-forth = _: { };

              keyboard = {
                xkb = {
                  layout = "pl";
                  options = "caps:escape";
                };
              };
            };

            layout = {
              gaps = 8;
              preset-column-widths = [
                { proportion = 0.32333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
              ];
              default-column-width.proportion = 0.50;
              focus-ring.width = 2;
            };

            workspaces = builtins.listToAttrs (
              builtins.concatMap (
                monitor:
                map (workspace: {
                  name = "${workspace}-${monitor}";
                  value =
                    { }
                    // lib.optionalAttrs (builtins.length config.monitors > 1) {
                      open-on-output = monitor;
                    };
                }) workspaces
              ) config.monitors
            );

            xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

            spawn-at-startup = [
              (lib.getExe noctaliaShellPkg)
              # handled by noctalia-shell, kept if ever needed
              # (lib.getExe (
              #   pkgs.writeShellScriptBin "swayidle" ''
              #     ${lib.getExe pkgs.swayidle} -w \
              #       timeout 180 '${lib.getExe' pkgs.systemd "loginctl"} lock-session' \
              #       timeout 600 '${lib.getExe' pkgs.systemd "systemctl"} suspend' \
              #       lock '${lib.getExe pkgs.swaylock} -f' \
              #       before-sleep '${lib.getExe' pkgs.systemd "loginctl"} lock-session' \
              #       unlock '${lib.getExe' pkgs.procps "pkill"} -f swaylock'
              #   ''
              # ))
            ];

            window-rules = [

            ];

            binds = {
              "Mod+Return".spawn =
                lib.getExe
                  self.packages."${pkgs.stdenv.hostPlatform.system}"."${config.terminal}";
              "Mod+Q".close-window = _: { };

              "Mod+F".toggle-window-floating = _: { };
              "Mod+Z".maximize-column = _: { };
              "Mod+Shift+Z".fullscreen-window = _: { };

              "Mod+H".focus-column-left-or-last = _: { };
              "Mod+L".focus-column-right-or-first = _: { };
              "Mod+K".focus-window-up-or-bottom = _: { };
              "Mod+J".focus-window-down-or-top = _: { };

              "Mod+Shift+H".move-column-left = _: { };
              "Mod+Shift+L".move-column-right = _: { };
              "Mod+Shift+K".move-window-up = _: { };
              "Mod+Shift+J".move-window-down = _: { };

              "Mod+Ctrl+H".consume-or-expel-window-left = _: { };
              "Mod+Ctrl+L".consume-or-expel-window-right = _: { };

              "Mod+Semicolon".move-window-to-monitor-next = _: { };
              "Mod+Period".focus-monitor-next = _: { };
              "Mod+Comma".focus-monitor-previous = _: { };

              "Print".screenshot-screen = _: { };
              "Mod+Print".screenshot-window = _: { };
              "Mod+Shift+Print".screenshot = _: { };

              "Mod+Tab" = _: {
                props = {
                  repeat = false;
                };
                content.toggle-overview = _: { };
              };
              "Mod+Shift+E".spawn = _: {
                props = [
                  (lib.getExe noctaliaShellPkg)
                  "ipc"
                  "call"
                  "sessionMenu"
                  "toggle"
                ];
              };

              "XF86AudioRaiseVolume" = _: {
                props = {
                  allow-when-locked = true;
                };
                content.spawn = _: {
                  props = [
                    (lib.getExe' pkgs.swayosd "swayosd-client")
                    "--output-volume"
                    "raise"
                  ];
                };
              };
              "XF86AudioLowerVolume" = _: {
                props = {
                  allow-when-locked = true;
                };
                content.spawn = _: {
                  props = [
                    (lib.getExe' pkgs.swayosd "swayosd-client")
                    "--output-volume"
                    "lower"
                  ];
                };
              };
              "XF86AudioMute" = _: {
                props = {
                  allow-when-locked = true;
                };
                content.spawn = _: {
                  props = [
                    (lib.getExe' pkgs.swayosd "swayosd-client")
                    "--output-volume"
                    "mute-toggle"
                  ];
                };
              };
              "XF86MonBrightnessUp" = _: {
                props = {
                  allow-when-locked = true;
                };
                content.spawn = _: {
                  props = [
                    (lib.getExe' pkgs.swayosd "swayosd-client")
                    "--brightness"
                    "raise"
                  ];
                };
              };
              "XF86MonBrightnessDown" = _: {
                props = {
                  allow-when-locked = true;
                };
                content.spawn = _: {
                  props = [
                    (lib.getExe' pkgs.swayosd "swayosd-client")
                    "--brightness"
                    "lower"
                  ];
                };
              };
              "XF86KbdBrightnessUp" = _: {
                props = {
                  allow-when-locked = true;
                };
                content.spawn = _: {
                  props = [
                    (lib.getExe' pkgs.swayosd "swayosd-client")
                    "--kbd-brightness"
                    "raise"
                  ];
                };
              };
              "XF86KbdBrightnessDown" = _: {
                props = {
                  allow-when-locked = true;
                };
                content.spawn = _: {
                  props = [
                    (lib.getExe' pkgs.swayosd "swayosd-client")
                    "--kbd-brightness"
                    "lower"
                  ];
                };
              };
            }
            // (lib.listToAttrs (
              lib.imap0 (i: ws: {
                name = "Mod+${toString (if i + 1 == 10 then 0 else i + 1)}";
                value.spawn = _: {
                  props = [
                    (lib.getExe niriSwitchWs)
                    ws
                  ];
                };
              }) workspaces
            ))
            // (lib.listToAttrs (
              lib.imap0 (i: ws: {
                name = "Mod+Shift+${toString (if i + 1 == 10 then 0 else i + 1)}";
                value.spawn = _: {
                  props = [
                    (lib.getExe niriSwitchWs)
                    ws
                    "--move"
                  ];
                };
              }) workspaces
            ));
          };

      };
    };
}
