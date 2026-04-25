{
  self,
  inputs,
  lib,
  ...
}:
let
  niriOptions = {
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
        "ghostty"
        "kitty"
      ];
      description = "Default terminal emulator to use";
      default = "ghostty";
    };

    noctalia = lib.mkOption {
      type = lib.types.submodule {
        options = {
          colors = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            description = "Noctalia custom color scheme";
            default = { };
          };
          extraSettings = lib.mkOption {
            type = lib.types.attrs;
            description = "Noctalia shell extra settings to be merged with defaults";
            default = { };
          };
          preInstalledPlugins = lib.mkOption {
            type = lib.types.attrs;
            description = "Same as wrapper-modules.noctualia-shell.options.preInstalledPlugins";
            default = { };
          };
        };
      };
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
        # security.pam.services.swaylock = { };

        environment.systemPackages = [
          inputs.noctalia.packages."${pkgs.stdenv.hostPlatform.system}".default
        ];

        security.pam.services.login = { };

        system.activationScripts = {
          niri-copy-wallpapers = {
            text = ''
              mkdir -p /var/lib/wallpapers
              cp -r ${../../../../assets/wallpapers}/* /var/lib/wallpapers
              chmod a=rX /var/lib/wallpapers
            '';
          };
        };

        services.gnome.gnome-keyring.enable = lib.mkForce (
          !(builtins.any (key: config.home-manager.users.${key}.programs.keepassxc.enable) (
            builtins.attrNames config.home-manager.users
          ))
        );

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
            noctaliaShellPkg = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
              inherit pkgs;
              inherit (config.noctalia) colors;

              package = inputs.noctalia.packages."${pkgs.stdenv.hostPlatform.system}".default;
              settings = lib.recursiveUpdate (lib.recursiveUpdate
                (builtins.fromJSON (builtins.readFile ./noctalia.json)).settings
                {
                  general = {
                    avatarImage = "${../../../../assets/avatar.png}";
                  };
                  wallpaper = {
                    directory = "/var/lib/wallpapers";
                  }
                  // lib.optionalAttrs (builtins.length config.displays > 1) {
                    enableMultiMonitorDirectories = true;
                    monitorDirectories = map (display: {
                      directory = "/var/lib/wallpapers";
                      name = display;
                    }) config.displays;

                  };
                }
              ) config.noctalia.extraSettings;

              preInstalledPlugins = {
                notes-scratchpad = {
                  src = "${./noctalia-plugins}/notes-scratchpad";
                  settings = {
                    panelWidth = 0.5;
                    panelHeight = 0.6;
                    fontSize = 14;
                    filePath = "~/Sync/sync/noctalia/notes-scratchpad.md";
                  };
                };
                todo = {
                  src = "${./noctalia-plugins}/todo";
                  settings = {
                    todos = [ ];
                    pages = [
                      {
                        id = 0;
                        name = "General";
                      }
                    ];
                    current_page_id = 0;
                    count = 0;
                    completedCount = 0;
                    showCompleted = false;
                    showBackground = true;
                    isExpanded = true;
                    useCustomColors = false;
                    priorityColors = {
                      high = "#f44336";
                      medium = "#2196f3";
                      low = "#9e9e9e";
                    };
                    todoFilePath = "~/Sync/sync/noctalia/todo.json";
                    exportPath = "~/Downloads";
                    exportFormat = "markdown";
                    exportEmptySections = false;
                  };
                };
              }
              // config.noctalia.preInstalledPlugins;
            };
          in
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
            // lib.optionalAttrs (builtins.elem "radeon" config.features) {
              LIBVA_DRIVERS_PATH = "${pkgs.mesa}/lib/dri/";
              LIBVA_DRIVER_NAME = "radeonsi";
              MOZ_DISABLE_RDD_SANDBOX = "1";
            }
            // lib.optionalAttrs (builtins.elem "iHD" config.features) {
              LIBVA_DRIVERS_PATH = "${pkgs.intel-media-driver}/lib/dri/";
              LIBVA_DRIVER_NAME = "iHD";
              MOZ_DISABLE_RDD_SANDBOX = "1";
            }
            // lib.optionalAttrs (builtins.elem "nvidia" config.features) {
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

            workspaces =
              let
                workspaceDisplay = lib.last config.displays;
              in
              {
                "1-thunderbird" = {
                  open-on-output = workspaceDisplay;
                };
                "2-obsidian" = {
                  open-on-output = workspaceDisplay;
                };
                "3-teams" = {
                  open-on-output = workspaceDisplay;
                };
                "4-telegram" = {
                  open-on-output = workspaceDisplay;
                };
                "5-discord" = {
                  open-on-output = workspaceDisplay;
                };
                "x-firefox" = {
                  open-on-output = workspaceDisplay;
                };
              };

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

            layer-rules = [
              {
                matches = [
                  {
                    namespace = "noctalia-notifications-.*";
                  }
                ];
                block-out-from = "screencast";
              }
            ];
            window-rules = [
              {
                matches = [
                  {
                    app-id = "org.keepassxc.KeePassXC";
                  }
                ];
                open-floating = true;
                open-focused = true;
                block-out-from = "screen-capture";
              }
              {
                matches = [
                  { app-id = "thunderbird"; }
                ];
                open-maximized = true;
                open-on-workspace = "1-thunderbird";
              }
              {
                matches = [
                  { title = "Obsidian"; }
                ];
                open-maximized = true;
                open-on-workspace = "2-obsidian";
              }
              {
                excludes = [
                  { title = "Obsidian"; }
                ];
                matches = [
                  { app-id = "electron"; }
                ];
                open-maximized = true;
                open-on-workspace = "3-teams";
              }
              {
                matches = [
                  { app-id = "org.telegram.desktop"; }
                ];
                open-maximized = true;
                open-on-workspace = "4-telegram";
              }
              {
                matches = [
                  { app-id = "discord"; }
                ];
                open-maximized = true;
                open-on-workspace = "5-discord";
              }
              {
                matches = [
                  { app-id = "firefox"; }
                ];
                open-maximized = true;
                open-on-workspace = "x-firefox";
              }
            ];

            binds = {
              "Mod+Return".spawn =
                lib.getExe
                  self.packages."${pkgs.stdenv.hostPlatform.system}"."${config.terminal}";
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
                  if config.launcher == "vicinae" then
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
                  if config.launcher == "vicinae" then
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
          };
      };
    };
}
