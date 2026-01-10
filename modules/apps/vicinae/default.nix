{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.vicinae;
in
{
  options.myHomeApps.vicinae = {
    enable = lib.mkEnableOption "vicinae";
    passwordManager = lib.mkOption {
      description = ''
        Configure password manager exposed by vicinal.
        Note - you may need to install corresponding extension first.
      '';
      type = lib.types.submodule {
        options = {
          type = lib.mkOption {
            type = lib.types.enum [ "bitwarden" ];
            description = "Type of password manager.";
            default = "bitwarden";
          };
          options = lib.mkOption {
            type = lib.types.submodule {
              options = {
                baseUrl = lib.mkOption {
                  type = lib.types.str;
                  default = if cfg.passwordManager.type == "bitwarden" then "https://vault.bitwarden.com" else "";
                  description = "Base Vault URL.";
                };
              };
            };
          };
        };
      };
    };
    features = lib.mkOption {
      description = "Enable/disable corresponding keybindings for given features.";
      type = lib.types.submodule {
        options = {
          launcher = lib.mkEnableOption "launcher" // {
            default = true;
          };
          # windowSwitcher = lib.mkEnableOption "window switcher" // {
          #   default = true;
          # };
          # sshShell = lib.mkEnableOption "ssh shell" // {
          #   default = true;
          # };
          clipboard = lib.mkEnableOption "clipboard" // {
            default = true;
          };
          passwordManager = lib.mkEnableOption "password manager" // {
            default = true;
          };
          # todoQuickAdd = lib.mkEnableOption "TODO quick add menu" // {
          #   default = true;
          # };
          # shutdownMenu = lib.mkEnableOption "shutdown menu" // {
          #   default = true;
          # };
        };
      };
      default = {
        launcher = true;
        # windowSwitcher = true;
        # sshShell = true;
        clipboard = true;
        passwordManager = true;
        # todoQuickAdd = true;
        # shutdownMenu = true;
      };
    };
  };

  config =
    let
      bwPkg = pkgs.bitwarden-cli;
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion =
            !config.myHomeApps.rofi.features.launcher || !config.myHomeApps.vicinae.features.launcher;
          message = "vicinae launcher cannot be enabled if rofi launcher is also there";
        }
        {
          assertion =
            !config.myHomeApps.rofi.features.clipboard || !config.myHomeApps.vicinae.features.clipboard;
          message = "vicinae clipboard cannot be enabled if rofi clipboard is also there";
        }
        {
          assertion =
            !config.myHomeApps.rofi.features.passwordManager
            || !config.myHomeApps.vicinae.features.passwordManager;
          message = "vicinae password manager cannot be enabled if rofi password manager is also there";
        }
      ];

      stylix.targets.vicinae.enable = true;

      myHomeApps = {
        extraPackages = lib.optionals cfg.features.passwordManager [ bwPkg ];
        awesome = {
          forcedFloatingClients.class = [ "vicinae" ];
          awfulRules = [
            {
              rule = {
                class = "vicinae";
              };
              properties = {
                border_width = 0;
                skip_taskbar = true;
              };
            }
          ];
          extraConfig = ''
            local vicinaekeys = gears.table.join(
          ''
          + (lib.optionalString cfg.features.launcher ''
            awful.key({ RC.vars.modkey }, "space", function()
              awful.util.spawn("${lib.getExe config.services.vicinae.package} toggle")
            end, { description = "command runner", group = "apps" }),'')
          + (lib.optionalString cfg.features.clipboard ''
            awful.key({ RC.vars.modkey, "Shift" }, "v", function()
              awful.util.spawn("${lib.getExe config.services.vicinae.package} vicinae://extensions/vicinae/clipboard/history")
            end, { description = "clipboard menu", group = "apps" }),'')
          + (lib.optionalString (cfg.features.passwordManager && cfg.passwordManager.type == "bitwarden") ''
            awful.key({ RC.vars.modkey, "Shift" }, "p", function()
              awful.util.spawn("${lib.getExe config.services.vicinae.package} vicinae://extensions/jomifepe/bitwarden/search")
            end, { description = "password menu", group = "apps" }),'')
          + ''
            awful.key({}, "", function()
            end, {})
            )
            RC.globalkeys = gears.table.join(RC.globalkeys, vicinaekeys)
            root.keys(RC.globalkeys)
          '';
        };
      };

      services.vicinae = {
        enable = true;
        systemd = {
          enable = true;
          autoStart = true;
          environment = {
            # workaround against service limitations
            PATH = "/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin";
          };
        };

        settings = {
          close_on_focus_loss = true;
          escape_key_behavior = "close_window";
          pop_to_root_on_close = true;
          launcher_window.opacity = 1.0;
          theme = {
            dark.name = "stylix";
            light.name = "stylix";
          };
        }
        // lib.optionalAttrs cfg.features.passwordManager {
          providers = lib.optionalAttrs (cfg.passwordManager.type == "bitwarden") {
            "@jomifepe/store.raycast.bitwarden" = {
              preferences = {
                cliPath = lib.getExe bwPkg;
                serverUrl = cfg.passwordManager.options.baseUrl;
              };
            };
          };
        };
      };
    };
}
