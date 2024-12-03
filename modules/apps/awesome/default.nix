{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.awesome;
in
{
  options.myHomeApps.awesome = {
    enable = lib.mkEnableOption "awesomewm";
    autorun = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of applications to run on awesome start.";
      default = [ ];
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      description = "Extra configuration appended at the end of rc.lua.";
      default = "";
    };
    modKey = lib.mkOption {
      type = lib.types.str;
      description = "Mod key for awesome.";
      default = "Mod4";
    };
    singleScreen = lib.mkOption {
      type = lib.types.bool;
      description = "Configure awesome for single screen instead of multi-monitor mode.";
      default = false;
    };
    useDunst = lib.mkOption {
      type = lib.types.bool;
      description = "Use dunst for notifications.";
      default = true;
    };
  };

  config = lib.mkIf (osConfig.mySystemApps.xorg.windowManager == "awesome") {
    xsession.windowManager.awesome.enable = true;
    myHomeApps = {
      dunst.enable = cfg.useDunst;
      # "${config.myHomeApps.xorg.terminal.pname}".enable = true; # causes infinite recursion
      alacritty.enable = config.myHomeApps.xorg.terminal.pname == "alacritty";
      kitty.enable = config.myHomeApps.xorg.terminal.pname == "kitty";
    };

    xdg = {
      configFile = {
        awesome = {
          source = ./config;
          recursive = true;
        };

        "awesome/rc.lua" = {
          text = (builtins.readFile ./rc.lua) + cfg.extraConfig;
        };

        "awesome/autorun.sh" = {
          executable = true;
          text = ''
            #!${lib.getExe' pkgs.coreutils "env"} ${lib.getExe pkgs.bash}

            run() {
              if ! ${lib.getExe' pkgs.procps "pgrep"} -f "/nix/store/.*/$(basename "$1")"; then
                "$@" &
              fi
            }

            ${builtins.concatStringsSep "\n" (builtins.map (app: "run ${app}") cfg.autorun)}

            ${lib.getExe config.services.betterlockscreen.package} -u ${config.xdg.dataHome}/wallpapers --fx dimpixel
          '';
        };

        "awesome/main/user-variables.lua" = {
          text = ''
            local _M = {
              autorandrPath = "${lib.getExe pkgs.autorandr}",
              scrotPath = "${lib.getExe pkgs.scrot}",
              slopPath = "${lib.getExe pkgs.slop}",
              xkillPath = "${lib.getExe pkgs.xorg.xkill}",

            	modkey = "${cfg.modKey}",
            	terminal = "${lib.getExe config.myHomeApps.xorg.terminal}",
              useDunst = ${if cfg.useDunst then "true" else "false"},
              singleScreen = ${if cfg.singleScreen then "true" else "false"},
            }

            return _M
          '';
        };

        # sound
        "awesome/scripts/volume.sh" = {
          executable = true;
          source = lib.getExe (
            pkgs.writeShellScriptBin "volume.sh" (
              if osConfig.myHardware.sound.enable then
                ''
                  bin_wpctl = "${lib.getExe' pkgs.wireplumber "wpctl"}"
                ''
                + builtins.readFile ./scripts/volume.sh
              else
                "# placeholder"
            )
          );
        };

        # dunst
        "awesome/scripts/dunst-widget.sh" = lib.mkIf cfg.useDunst {
          executable = true;
          source = lib.getExe (
            pkgs.writeShellScriptBin "dunst-widget.sh" (builtins.readFile ./scripts/dunst-widget.sh)
          );
        };
      };
      dataFile = {
        wallpapers = {
          source = ./wallpapers;
          recursive = true;
        };
      };
    };

    services.betterlockscreen = {
      enable = true;
      inactiveInterval = 3;
      arguments = [
        "dimpixel"
        "--off"
        "30"
      ];
    };
  };
}
