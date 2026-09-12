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
    in
    {
      options.features.home.noctalia-shell = {
        extraSettings = lib.mkOption {
          type = lib.types.attrs;
          description = "Noctalia extra settings to be merged with defaults";
          default = { };
        };
      };

      config = {
        # The v5 todo plugin has no IPC entry point for adding a task, so the
        # vicinae "Add Todo" command pokes its JSON store directly. The plugin
        # re-reads the file every couple of seconds.
        home.packages = [
          (pkgs.writeShellApplication {
            name = "noctalia-add-todo";
            runtimeInputs = [ pkgs.jq ];
            text = ''
              file="''${NOCTALIA_TODO_FILE:-$HOME/Sync/sync/noctalia/todo.json}"

              if [ "''${1:-}" = "--work" ]; then
                shift
                text="$* @work"
              else
                text="$*"
              fi

              [ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ] || exit 0
              mkdir -p "$(dirname "$file")"
              [ -s "$file" ] || printf '{}' >"$file"

              tmp="$(mktemp "$file.XXXXXX")"
              trap 'rm -f "$tmp"' EXIT
              jq --arg text "$text" '
                (if type == "array" then { version: 2, sort: "priority", tasks: . } else . end)
                | .tasks = (.tasks // [])
                | .tasks += [{
                    id: ((.tasks | map(.id) | max // 0) + 1),
                    text: $text,
                    priority: "medium",
                    done: false
                  }]
                | { version: 2, sort: (.sort // "priority"), tasks: .tasks }
              ' "$file" >"$tmp"
              cat "$tmp" >"$file"
            '';
          })
        ];

        xdg.configFile = {
          # hm and noctalia fight over this file
          "gtk-4.0/gtk.css".force = true;
          "noctalia/templates".source = ./templates;
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

        programs.noctalia = {
          enable = true;

          settings = lib.recursiveUpdate {
            shell = {
              avatar_path = "${../../../../assets/avatar.png}";
            };

            bar.main = {
              position = "top";
              # Full-width bar with square corners. `radius` seeds all four
              # corners, so it squares them on its own; `concave_edge_corners`
              # then has nothing to carve, but keep it off explicitly.
              margin_ends = 0;
              radius = 0;
              concave_edge_corners = false;

              # v4 `bar.mouseWheelAction = "workspace"`, which only ever applied
              # to the empty bar area - v5 calls that the dead zone.
              dead_zone.actions = {
                scroll_up = "workspace-switch prev";
                scroll_down = "workspace-switch next";
              };
            };

            backdrop.enabled = true; # v4 `wallpaper.overviewEnabled`

            brightness.enable_ddcutil = true;

            desktop_widgets.enabled = false;

            dock.enabled = false;

            idle = {
              # v4 `idle.fadeDuration`
              pre_action_fade_seconds = 2;
              behavior = {
                lock = {
                  enabled = true;
                  action = "lock";
                  timeout = 120;
                };
                screen-off = {
                  enabled = true;
                  action = "screen_off";
                  timeout = 180;
                };
                suspend = {
                  enabled = true;
                  action = "lock_and_suspend";
                  timeout = 300;
                };
              };
            };

            location = {
              auto_locate = false;
              address = "Krakow, PL";
            };

            nightlight.enabled = true;

            notification = {
              enable_daemon = true;
              # v4 ran a python d-bus proxy that rewrote these senders to critical
              # urgency so they would stick around (`criticalUrgencyDuration`).
              # v5 does it natively: 8h forced display duration.
              filter_order = [
                "teams"
                "telegram"
              ];
              filter = {
                teams = {
                  enabled = true;
                  match = "teams-for-linux";
                  allow_permanent = true;
                  override_duration = 28800000; # 8h
                };
                telegram = {
                  enabled = true;
                  match = "org.telegram.desktop";
                  allow_permanent = true;
                  override_duration = 28800000; # 8h
                };
              };
            };

            theme = {
              mode = self.theme.polarity;
              source = "builtin";
              builtin = self.theme.capitalizedName;

              templates = {
                enable_builtin_templates = true;
                builtin_ids = [
                  "gtk3"
                  "gtk4"
                  "qt"
                ];
                enable_community_templates = true;
                community_ids = [ ];
                # v4 `user-templates.toml`
                user.supersonic = {
                  input_path = "$XDG_CONFIG_HOME/noctalia/templates/supersonic.toml";
                  output_path = "$XDG_CONFIG_HOME/supersonic/themes/noctalia.toml";
                };
              };
            };

            wallpaper = {
              directory = "${../../../../assets/wallpapers}";
              per_monitor_directories = true;
              transition = [ "honeycomb" ]; # v4 "pixelate" has no v5 equivalent
              transition_duration = 1500;
              transition_on_startup = true; # v4 behaviour
              edge_smoothness = 0;
              automation = {
                enabled = true;
                interval_seconds = 900;
                order = "random";
              };
            };

            plugins = {
              auto_update = "all";
              enabled = [
                "ahmedhossamdev/sticky-notes"
                "nightwatch75/todo"
              ];
            };
          } cfg.extraSettings;
        };
      };
    };
}
