{
  config,
  lib,
  pkgs,
  pkgs-stable,
  ...
}:
let
  cfg = config.myHomeApps.rofi;
in
{
  options.myHomeApps.rofi = {
    enable = lib.mkEnableOption "rofi";
    passwordManager = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "bitwarden" ]);
      description = "Password manager to integratae with rofi.";
      default = null;
    };
    bitwarden = lib.mkOption {
      type = lib.types.submodule {
        options = {
          email = lib.mkOption {
            type = lib.types.str;
            description = "Sign in email for the vault.";
          };
          base_url = lib.mkOption {
            type = lib.types.str;
            description = "URL of the vault.";
          };
        };
      };
      default = { };
    };
    todoCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Command to run, when adding todo task.";
      default = null;
    };
  };

  config =
    let
      rofiPackage = pkgs.rofi.override { plugins = [ pkgs.rofi-emoji ]; };
      pinentryRofi = pkgs.writeShellApplication {
        name = "pinentry-rofi-with-env";
        text = ''
          PATH="$PATH:${pkgs.coreutils-full}/bin:${rofiPackage}/bin"
          "${
            lib.getExe (
              pkgs.pinentry-rofi.overrideAttrs {
                # guile 3.x sometimes works, sometimes breaks pinentry rofi for some reason...
                # buildInputs = [ pkgs.guile_2_2 ];
              }
            )
          }" "$@" -- -theme ${config.xdg.configHome}/rofi/pinentry/config.rasi -normal-window
        '';
        meta = {
          mainProgram = "pinentry-rofi-with-env";
        };
      };
    in
    lib.mkIf cfg.enable {
      stylix.targets.rofi.enable = true;
      myHomeApps.gnupg.pinentryPackage = pinentryRofi;

      home = {
        packages = [
          pkgs.haskellPackages.greenclip
          pkgs.xdotool
          (pkgs.callPackage ./font.nix { })
        ]
        ++ lib.optionals (cfg.passwordManager != null) [ pkgs.rofi-rbw ];

        activation = {
          greenclip = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run mkdir -p ${config.xdg.cacheHome}/greenclip || true
          '';
        };
      };

      programs = {
        rbw = lib.mkIf (cfg.passwordManager == "bitwarden") {
          enable = true;
          package = pkgs-stable.rbw; # TODO: rbw 1.14.x introduces major regression, wait for fix
          settings = {
            inherit (cfg.bitwarden) email base_url;
            lock_timeout = 14400; # 4h
            pinentry = pkgs.pinentry-gtk2;
          };
        };

        rofi = {
          enable = true;
          package = rofiPackage;
        };
      };

      systemd.user.services.greenclip = {
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
        Unit = {
          Description = "Greenclip clipboard manager";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${lib.getExe pkgs.haskellPackages.greenclip} daemon";
          Restart = "always";
          RestartSec = 3;
        };
      };

      myHomeApps.awesome = {
        forcedFloatingClients.name = [ "rofi - Passphrase:" ];
        extraConfig = ''
          local home = os.getenv("HOME")
          local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
          local rofikeys = gears.table.join(
            awful.key({ RC.vars.modkey }, "space", function()
              awful.util.spawn("${lib.getExe rofiPackage} -show drun -theme " .. xdg_config_home .. "/rofi/drun/config.rasi")
            end, { description = "command runner", group = "apps" }),
            awful.key({ RC.vars.modkey }, "Tab", function()
              awful.util.spawn("${lib.getExe rofiPackage} -show window -theme " .. xdg_config_home .. "/rofi/drun/config.rasi -window-command '"
                .. xdg_config_home .. "/rofi/window/focus-window.sh {window}' -kb-accept-entry ''' " ..
                "-kb-accept-alt 'Return,KP_Enter'")
            end, { description = "window switcher", group = "apps" }),
            awful.key({ RC.vars.modkey, "Shift" }, "s", function()
              awful.util.spawn(xdg_config_home .. "/rofi/generic/ssh.sh")
            end, { description = "ssh shell", group = "apps" }),
            awful.key({ RC.vars.modkey, "Shift" }, "v", function()
              awful.util.spawn(
                "${lib.getExe rofiPackage} -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}' -theme "
                  .. xdg_config_home
                  .. "/rofi/generic/config.rasi"
              )
            end, { description = "clipboard menu", group = "apps" }),
        ''
        + (lib.optionalString (cfg.passwordManager == "bitwarden") ''
          awful.key({ RC.vars.modkey, "Shift" }, "p", function()
            awful.util.spawn(
              "${lib.getExe pkgs.rofi-rbw} --selector-args=\"-kb-move-char-back ''' -kb-secondary-copy ''' -theme "
                .. xdg_config_home
                .. '/rofi/generic/config.rasi" --prompt="󱉼" '
                .. '--keybindings="Control+b:type:username,Control+c:type:password,Control+t:type:totp"'
            )
          end, { description = "password manager", group = "apps" }),
        '')
        + (lib.optionalString (cfg.todoCommand != null) ''
          awful.key({ RC.vars.modkey }, "e", function()
            awful.util.spawn("${lib.getExe rofiPackage} -show TODO -modi TODO:"
              .. xdg_config_home
              .. "/rofi/todo/todo.sh "
              .. "-theme "
              .. xdg_config_home
              .. "/rofi/todo/config.rasi"
            )
          end, { description = "password manager", group = "apps" }),
        '')
        + ''
            awful.key({ RC.vars.modkey, "Shift" }, "e", function()
              awful.util.spawn(xdg_config_home .. "/rofi/powermenu/powermenu.sh")
            end, { description = "shutdown menu", group = "apps" })
          )

          RC.globalkeys = gears.table.join(RC.globalkeys, rofikeys)
          root.keys(RC.globalkeys)
        '';
      };

      xdg.configFile = {
        rofi = {
          source = ./config;
          recursive = true;
        };

        "rofi/generic/ssh.sh" = {
          executable = true;
          source = lib.getExe (
            pkgs.writeShellScriptBin "rofi-ssh.sh" ''
              host=$(cat "$HOME/.ssh/config" | grep Include | awk '{print $2}' | xargs cat "$HOME/.ssh/config" | grep '^Host' | grep -vE '\*|\.' | awk '{print $2}' | sort | ${lib.getExe rofiPackage} -dmenu -p "ssh" -theme ${config.xdg.configHome}/rofi/generic/config.rasi)

              if [ -n "$host" ]; then
                export DISABLE_MOTD=1
                # true && ... - it's a hack to invoke SSH command properly on ghostty
                ${lib.getExe config.myHomeApps.xorg.terminal} -e ${lib.getExe pkgs.zsh} -ic "true && ${lib.getExe pkgs.openssh} $host"
              fi
            ''
          );
        };
        "rofi/powermenu/powermenu.sh" = {
          executable = true;
          source = lib.getExe (
            pkgs.writeShellScriptBin "rofi-powermenu.sh" (
              ''
                convert_cmd="${lib.getExe' pkgs.imagemagick "convert"}"
                rofi_cmd="${lib.getExe rofiPackage}"
                scrot_cmd="${lib.getExe pkgs.scrot}"
                sed_cmd="${lib.getExe pkgs.gnused}"
                uptime_cmd="${lib.getExe' pkgs.coreutils "uptime"}"
              ''
              + builtins.readFile ./scripts/powermenu.sh
            )
          );
        };
        "rofi/window/focus-window.sh" = {
          executable = true;
          source = pkgs.writeShellScriptBin "rofi-focus-window.sh" ''
            echo "
            for _, c in ipairs(client.get()) do
              if c.window == $1 then
                c:tags()[1]:view_only()
                client.focus = c
                c:raise()
              end
            end
            " | ${lib.getExe' pkgs.awesome "awesome-client"}
          '';
        };
        "greenclip.toml" = {
          text = ''
            [greenclip]
              blacklisted_applications = []
              enable_image_support = true
              history_file = "${config.xdg.cacheHome}/greenclip/history"
              image_cache_directory = "${config.xdg.cacheHome}/greenclip/image"
              max_history_length = 500
              max_selection_size_bytes = 0
              static_history = []
              trim_space_from_selection = true
              use_primary_selection_as_input = false
          '';
        };
      }
      // lib.optionalAttrs (cfg.todoCommand != null) {
        "rofi/todo/todo.sh" = {
          executable = true;
          source = lib.getExe (
            pkgs.writeShellScriptBin "rofi-todo.sh" ''
              if [ -n "$*" ]; then
                ${cfg.todoCommand} "$*" || ${lib.getExe' pkgs.libnotify "notify-send"} -u critical "Error adding TODO item"
              fi
            ''
          );
        };
      };
    };
}
