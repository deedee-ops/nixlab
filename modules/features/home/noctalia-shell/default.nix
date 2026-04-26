{ self, ... }:
{
  flake.homeModules.features-home-noctalia-shell =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.noctalia-shell;
      defaultPlugins = {
        notes-scratchpad = {
          source = ./plugins/notes-scratchpad;
          sourceUrl = null;
          settings = {
            panelWidth = 0.5;
            panelHeight = 0.6;
            fontSize = 14;
            filePath = "~/Sync/sync/noctalia/notes-scratchpad.md";
          };
        };

        todo = {
          source = ./plugins/todo;
          sourceUrl = null;
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
      };
    in
    {

      options.features.home.noctalia-shell = {
        extraSettings = lib.mkOption {
          type = lib.types.attrs;
          description = "Noctalia shell extra settings to be merged with defaults";
          default = { };
        };
        plugins = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                source = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  description = "Path to plugin source, takes priority over URL";
                  default = null;
                };
                sourceUrl = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "URL to plugin source";
                  default = null;
                };
                settings = lib.mkOption {
                  type = lib.types.attrs;
                  description = "Plugin settings";
                  default = { };
                };
              };
            }
          );
          default = { };
        };
      };

      config = {
        xdg.configFile =
          (lib.concatMapAttrs (
            pluginName: pluginCfg:
            lib.mapAttrs' (fileName: _: {
              name = "noctalia/plugins/${pluginName}/${fileName}";
              value = {
                source = pluginCfg.source + "/${fileName}";
              };
            }) (builtins.readDir pluginCfg.source)
          ) (lib.filterAttrs (_: pluginCfg: pluginCfg.source != null) (defaultPlugins // cfg.plugins)))
          // {
            # # hm and noctalia fight over this file
            "gtk-4.0/gtk.css".force = true;
            "noctalia/templates".source = ./templates;
            "noctalia/user-templates.toml".text = ''
              [config]

              [templates.supersonic]
              input_path = "${config.xdg.configHome}/noctalia/templates/supersonic.toml"
              output_path = "${config.xdg.configHome}/supersonic/themes/noctalia.toml"
            '';
          };

        gtk = rec {
          theme = {
            name = "adw-gtk3";
            package = pkgs.adw-gtk3;
          };
          gtk3.theme = theme;
          gtk4.theme = theme;
        };
        qt = {
          enable = true;
          platformTheme.name = "gtk3"; # align with gtk3
        };

        programs.noctalia-shell = {
          enable = true;

          colors = lib.mkForce { };
          settings = lib.recursiveUpdate {
            general = {
              avatarImage = "${../../../../assets/avatar.png}";
              showChangelogOnStartup = false;
              enableLockScreenCountdown = false;
            };
            bar = {
              outerCorners = false;
              mouseWheelAction = "workspace";
            };
            brightness = {
              enableDdcSupport = true;
            };
            colorSchemes = {
              predefinedScheme = self.theme.capitalizedName;
            };
            desktopWidgets = {
              enabled = true;
            };
            dock = {
              enable = false;
            };
            idle = {
              enabled = true;
              screenOffTimeout = 180;
              lockTimeout = 120;
              suspendTimeout = 300;
              fadeDuration = 2;
            };
            location = {
              name = "Krakow, PL";
            };
            nightLight = {
              enabled = true;
            };
            sessionMenu = {
              enableCountdown = false;
            };
            templates = {
              activeTemplates = [
                {
                  enabled = true;
                  id = "gtk";
                }
                {
                  enabled = true;
                  id = "qt";
                }
              ];
              enableUserTheming = true;
            };
            wallpaper = {
              directory = ../../../../assets/wallpapers;
              enableMultiMonitorDirectories = true;
              automationEnabled = true;
              randomIntervalSec = 900;
              transitionDuration = 500;
              transitionType = [ ];
              transitionEdgeSmoothness = 0;
            };
          } cfg.extraSettings;

          plugins.states = builtins.mapAttrs (_: value: {
            enabled = true;
            sourceUrl = if (value.source == null) then value.sourceUrl else null;
          }) (defaultPlugins // cfg.plugins);

          pluginSettings = builtins.mapAttrs (_: value: value.settings) (defaultPlugins // cfg.plugins);
        };
      };
    };
}
