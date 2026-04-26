{ inputs, ... }:
{
  flake.homeModules.features-home-niri =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.niri;
    in
    {
      options.features.home.niri = {
        displays = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = ''
            List of displays detected and expected to be supported by niri.
            To determine them use: `niri msg outputs`
          '';
          default = [ "default" ]; # for one monitor whole logic will be ignored
          example = [
            "DP-1"
            "HDMI-A-1"
          ];
        };

        launcher = lib.mkOption {
          type = lib.types.enum [
            "noctalia-shell"
            "vicinae"
          ];
          description = "Dafault launcher";
          default = "noctalia-shell";
        };

        terminal = lib.mkOption {
          type = lib.types.enum [
            "kitty"
          ];
          description = "Default terminal emulator to use";
          default = "kitty";
        };

        features = lib.mkOption {
          type = lib.types.listOf (
            lib.types.enum [
              "radeon"
              "iHD"
              "nvidia"
            ]
          );
          description = "Extra features enabled in niri configs";
          default = [ ];
        };
      };
      config = {
        programs.noctalia-shell.settings.templates.activeTemplates = [
          {
            enabled = true;
            id = "niri";
          }
        ];
        home.activation.init-niri = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # ensure noctalia.kdl exists otherwise niri will fail to include it and start
          touch "${config.xdg.configHome}/niri/noctalia.kdl"
        '';
        xdg.configFile."niri/config.kdl".text =
          let
            inherit (inputs.wrapper-modules.lib) toKdl;

            noctaliaShellPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
          in
          (toKdl (
            {
              prefer-no-csd = _: { };
              screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d-%H%M%S_scrot.png";
              hotkey-overlay.skip-at-startup = _: { };
              gestures.hot-corners.off = _: { };

              environment = {
                DISPLAY = ":0"; # for xwayland-satellite
                GTK_USE_PORTAL = "0";
                MOZ_ENABLE_WAYLAND = "1";
                MOZ_DBUS_REMOTE = "1";
                QT_QPA_PLATFORMTHEME = "qt6ct";
                QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
                WAYLAND_DISPLAY = "wayland-1";
                XDG_CURRENT_DESKTOP = "niri";
                XDG_SESSION_TYPE = "wayland";

                # tell various apps we use wayland
                CLUTTER_BACKEND = "wayland";
                EGL_PLATFORM = "wayland";
                GDK_BACKEND = "wayland,x11";
                NIXOS_OZONE_WL = "1";
                QT_QPA_PLATFORM = "wayland";
                SDL_VIDEODRIVER = "wayland,x11";
                _JAVA_AWT_WM_NONREPARENTING = "1";
              }
              // lib.optionalAttrs (builtins.elem "radeon" cfg.features) {
                LIBVA_DRIVERS_PATH = "${pkgs.mesa}/lib/dri/";
                LIBVA_DRIVER_NAME = "radeonsi";
                MOZ_DISABLE_RDD_SANDBOX = "1";
              }
              // lib.optionalAttrs (builtins.elem "iHD" cfg.features) {
                LIBVA_DRIVERS_PATH = "${pkgs.intel-media-driver}/lib/dri/";
                LIBVA_DRIVER_NAME = "iHD";
                MOZ_DISABLE_RDD_SANDBOX = "1";
              }
              // lib.optionalAttrs (builtins.elem "nvidia" cfg.features) {
                LIBVA_DRIVERS_PATH = "${pkgs.nvidia-vaapi-driver}/lib/dri/";
                LIBVA_DRIVER_NAME = "nvidia";
                MOZ_DISABLE_RDD_SANDBOX = "1";
                NVD_BACKEND = "direct";
              };

              cursor = {
                xcursor-size = 24;
                hide-after-inactive-ms = 3000;
              };

              input = {
                workspace-auto-back-and-forth = _: { };
                focus-follows-mouse = _: {
                  props = {
                    max-scroll-amount = "95%";
                  };
                };

                keyboard = {
                  xkb = {
                    layout = "pl";
                    options = "caps:escape";
                  };
                };

                touchpad = {
                  tap = _: { };
                  drag = true;
                  drag-lock = _: { };
                  dwt = _: { };
                  tap-button-map = "left-right-middle";
                  click-method = "clickfinger";
                };
              };

              layout = {
                gaps = 8;
                preset-column-widths = [
                  { proportion = 0.33333; }
                  { proportion = 0.5; }
                  { proportion = 0.66667; }
                ];
                default-column-width.proportion = 0.50;
                focus-ring.width = 2;
              };

              xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

              spawn-at-startup = [ (lib.getExe noctaliaShellPkg) ];

              binds = {
                "Mod+Return".spawn = lib.getExe config.programs."${cfg.terminal}".package;
                "Mod+Shift+Q".close-window = _: { };

                "Mod+F".toggle-window-floating = _: { };
                "Mod+Z".maximize-column = _: { };
                "Mod+Shift+Z".fullscreen-window = _: { };

                "Mod+H".focus-column-left-or-last = _: { };
                "Mod+L".focus-column-right-or-first = _: { };
                "Mod+K".focus-window-or-workspace-up = _: { };
                "Mod+J".focus-window-or-workspace-down = _: { };

                "Mod+Shift+H".move-column-left = _: { };
                "Mod+Shift+L".move-column-right = _: { };
                "Mod+Shift+K".move-window-up-or-to-workspace-up = _: { };
                "Mod+Shift+J".move-window-down-or-to-workspace-down = _: { };

                "Mod+Shift+G".switch-preset-column-width = _: { };

                "Mod+Ctrl+H".consume-or-expel-window-left = _: { };
                "Mod+Ctrl+L".consume-or-expel-window-right = _: { };

                "Mod+Shift+Period".move-window-to-monitor-next = _: { };
                "Mod+Shift+Comma".move-window-to-monitor-previous = _: { };
                "Mod+Period".focus-monitor-next = _: { };
                "Mod+Comma".focus-monitor-previous = _: { };

                "Print".screenshot-screen = _: { };
                "Mod+Print".screenshot-window = _: { };
                "Mod+Shift+Print".screenshot = _: { };

                "Mod+Space".spawn = _: {
                  props =
                    if cfg.launcher == "vicinae" then
                      [
                        (lib.getExe inputs.vicinae.packages."${pkgs.stdenv.hostPlatform.system}".default)
                        "toggle"
                      ]
                    else
                      [
                        (lib.getExe noctaliaShellPkg)
                        "ipc"
                        "call"
                        "launcher"
                        "toggle"
                      ];
                };
                "Mod+Shift+V".spawn = _: {
                  props =
                    if cfg.launcher == "vicinae" then
                      [
                        (lib.getExe inputs.vicinae.packages."${pkgs.stdenv.hostPlatform.system}".default)
                        "vicinae://extensions/vicinae/clipboard/history"
                      ]
                    else
                      [
                        (lib.getExe noctaliaShellPkg)
                        "ipc"
                        "call"
                        "launcher"
                        "clipboard"
                      ];
                };

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
                "Mod+Grave".spawn = _: {
                  props = [
                    (lib.getExe noctaliaShellPkg)
                    "ipc"
                    "call"
                    "notifications"
                    "toggleHistory"
                  ];
                };

                "Mod+E".spawn = _: {
                  props = [
                    (lib.getExe noctaliaShellPkg)
                    "ipc"
                    "call"
                    "plugin:todo"
                    "togglePanel"
                  ];
                };
                "Mod+A".spawn = _: {
                  props = [
                    (lib.getExe noctaliaShellPkg)
                    "ipc"
                    "call"
                    "plugin:notes-scratchpad"
                    "togglePanel"
                  ];
                };

                "XF86AudioRaiseVolume" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "volume"
                      "increase"
                    ];
                  };
                };
                "XF86AudioLowerVolume" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "volume"
                      "decrease"
                    ];
                  };
                };
                "XF86AudioMute" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "volume"
                      "muteOutput"
                    ];
                  };
                };
                "XF86MonBrightnessUp" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "brightness"
                      "increase"
                    ];
                  };
                };
                "XF86MonBrightnessDown" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "brightness"
                      "decrease"
                    ];
                  };
                };
                "XF86AudioPlay" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "media"
                      "playPause"
                    ];
                  };
                };
                "XF86AudioStop" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "media"
                      "stop"
                    ];
                  };
                };
                "XF86AudioNext" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "media"
                      "next"
                    ];
                  };
                };
                "XF86AudioPrev" = _: {
                  props = {
                    allow-when-locked = true;
                  };
                  content.spawn = _: {
                    props = [
                      (lib.getExe noctaliaShellPkg)
                      "ipc"
                      "call"
                      "media"
                      "previous"
                    ];
                  };
                };

                "Mod+1".focus-workspace = "1-thunderbird";
                "Mod+2".focus-workspace = "2-obsidian";
                "Mod+3".focus-workspace = "3-teams";
                "Mod+4".focus-workspace = "4-telegram";
                "Mod+5".focus-workspace = "5-discord";
                "Mod+0".focus-workspace = "x-firefox";
              };
            }
            // lib.optionalAttrs config.programs.noctalia-shell.enable {
              include = "${config.xdg.configHome}/niri/noctalia.kdl";
            }
          ))
          + "\n"
          + (toKdl (
            builtins.map
              (workspace: {
                workspace = _: {
                  props = [ workspace ];
                  content.open-on-output = lib.last cfg.displays;
                };
              })
              [
                "1-thunderbird"
                "2-obsidian"
                "3-teams"
                "4-telegram"
                "5-discord"
                "x-firefox"
              ]
          ))
          + "\n"
          + (toKdl [
            {
              window-rule = {
                match = _: {
                  props = {
                    app-id = "org.keepassxc.KeePassXC";
                    title = "Unlock Database";
                  };
                };
                open-floating = true;
                open-focused = true;
              };
            }
            {
              window-rule = {
                match = _: {
                  props = {
                    app-id = "org.keepassxc.KeePassXC";
                  };
                };
                block-out-from = "screen-capture";
              };
            }
            {
              window-rule = {
                match = _: {
                  props = {
                    app-id = "thunderbird";
                  };
                };
                open-maximized = true;
                open-on-workspace = "1-thunderbird";
              };
            }
            {
              window-rule = {
                match = _: {
                  props = {
                    title = "Obsidian";
                  };
                };
                open-maximized = true;
                open-on-workspace = "2-obsidian";
              };
            }
            {
              window-rule = {
                match = _: {
                  props = {
                    app-id = "electron";
                  };
                };
                exclude = _: {
                  props = {
                    title = "Obsidian";
                  };
                };
                open-maximized = true;
                open-on-workspace = "3-teams";
              };
            }
            {
              window-rule = {
                match = _: {
                  props = {
                    app-id = "org.telegram.desktop";
                  };
                };
                open-maximized = true;
                open-on-workspace = "4-telegram";
              };
            }
            {
              window-rule = {
                match = _: {
                  props = {
                    app-id = "vesktop";
                  };
                };
                open-maximized = true;
                open-on-workspace = "5-discord";
              };
            }
            {
              window-rule = {
                match = _: {
                  props = {
                    app-id = "firefox";
                  };
                };
                open-maximized = true;
                open-on-workspace = "x-firefox";
              };
            }
            {
              layer-rule = {
                match = _: {
                  props = {
                    namespace = "noctalia-notifications-.*";
                  };
                };
                block-out-from = "screencast";
              };
            }
          ]);
      };
    };
}
