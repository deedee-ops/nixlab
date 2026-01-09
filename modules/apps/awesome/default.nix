{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.awesome;
  clientSubmodule = lib.types.submodule {
    options = {
      instance = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Floating windows by instance.";
        default = [ ];
      };
      class = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Floating windows by class.";
        default = [ ];
      };
      name = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Floating windows by name.";
        default = [ ];
      };
      role = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Floating windows by role.";
        default = [ ];
      };
    };
  };

in
{
  options.myHomeApps.awesome = {
    enable = lib.mkEnableOption "awesomewm";
    package = lib.mkPackageOption pkgs "awesome-git" { };
    autorun = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of applications to run on awesome start.";
      default = [ ];
    };
    awfulRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Extra awful rules.";
      default = [ ];
      example = [
        {
          rule = {
            class = "my-window";
          };
          properties = {
            screen = 1;
            tag = " 3 ";
          };
        }
      ];
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      description = "Extra configuration appended at the end of rc.lua.";
      default = "";
    };
    floatingClients = lib.mkOption {
      type = clientSubmodule;
      description = "Rules for windows which should be floating.";
      default = { };
    };
    forcedFloatingClients = lib.mkOption {
      type = clientSubmodule;
      description = "Rules for windows which should be floating, always on top on always visible regardless of screen or tag.";
      default = { };
    };
    modKey = lib.mkOption {
      type = lib.types.str;
      description = "Mod key for awesome.";
      default = "Mod4";
    };
    showBattery = lib.mkOption {
      type = lib.types.bool;
      description = "Show battery indicator.";
      default = false;
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
    xsession.windowManager.awesome = {
      inherit (cfg) package;
      enable = true;
    };
    myHomeApps = {
      dunst.enable = cfg.useDunst;
    }
    // (builtins.listToAttrs (
      builtins.map (term: {
        name = term;
        value.enable = config.myHomeApps.xorg.terminal.pname == term;
      }) osConfig.mySystem.supportedTerminals
    ));

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
          source = lib.getExe (
            pkgs.writeShellScriptBin "autorun.sh" ''
              ${builtins.concatStringsSep "\n" (builtins.map (app: "${app} &") cfg.autorun)}

              ${lib.getExe config.services.betterlockscreen.package} -u ${config.xdg.dataHome}/wallpapers --fx dimpixel
            ''
          );
        };

        "awesome/main/user-variables.lua" = {
          text = ''
            local _M = {
              autorandrPath = "${lib.getExe pkgs.autorandr}",
              scrotPath = "${lib.getExe pkgs.scrot}",
              slopPath = "${lib.getExe pkgs.slop}",
              xkillPath = "${lib.getExe pkgs.xorg.xkill}",
              xsetPath = "${lib.getExe pkgs.xorg.xset}",

            	modkey = "${cfg.modKey}",
            	terminal = "${lib.getExe config.myHomeApps.xorg.terminal}",
              showBattery = ${if cfg.showBattery then "true" else "false"},
              useDunst = ${if cfg.useDunst then "true" else "false"},
              singleScreen = ${if cfg.singleScreen then "true" else "false"},

              floatingInstance = { ${
                builtins.concatStringsSep "," (
                  builtins.map (item: "\"${item}\"") (
                    [
                      "copyq"
                    ]
                    ++ cfg.floatingClients.instance
                  )
                )
              } },
              floatingClass = { ${
                builtins.concatStringsSep "," (
                  builtins.map (item: "\"${item}\"") (
                    [
                      "Arandr"
                      "Blueman-manager"
                    ]
                    ++ cfg.floatingClients.class
                  )
                )
              } },
              floatingName = { ${
                builtins.concatStringsSep "," (
                  builtins.map (item: "\"${item}\"") ([ "Event Tester" ] ++ cfg.floatingClients.name)
                )
              } },
              floatingRole = { ${
                builtins.concatStringsSep "," (
                  builtins.map (item: "\"${item}\"") ([ "GtkFileChooserDialog" ] ++ cfg.floatingClients.role)
                )
              } },

              forcedFloatingInstance = { ${
                builtins.concatStringsSep "," (
                  builtins.map (item: "\"${item}\"") (
                    [
                      "pinentry"
                    ]
                    ++ cfg.forcedFloatingClients.instance
                  )
                )
              } },
              forcedFloatingClass = { ${
                builtins.concatStringsSep "," (builtins.map (item: "\"${item}\"") cfg.forcedFloatingClients.class)
              } },
              forcedFloatingName = { ${
                builtins.concatStringsSep "," (builtins.map (item: "\"${item}\"") cfg.forcedFloatingClients.name)
              } },
              forcedFloatingRole = { ${
                builtins.concatStringsSep "," (builtins.map (item: "\"${item}\"") cfg.forcedFloatingClients.role)
              } },

              extraAwfulRules = ${lib.generators.toLua { } cfg.awfulRules},
            }

            return _M
          '';
        };

        # battery
        "awesome/scripts/battery.sh" = {
          executable = true;
          source = lib.getExe (
            pkgs.writeShellScriptBin "battery.sh" (builtins.readFile ./scripts/battery.sh)
          );
        };

        # brightness
        "awesome/scripts/brightness.sh" = {
          executable = true;
          source = lib.getExe (
            pkgs.writeShellScriptBin "brightness.sh" (builtins.readFile ./scripts/brightness.sh)
          );
        };

        # sound
        "awesome/scripts/volume.sh" = {
          executable = true;
          source = lib.getExe (
            pkgs.writeShellScriptBin "volume.sh" (
              if osConfig.myHardware.sound.enable then
                ''
                  bin_wpctl = "${lib.getExe' osConfig.services.pipewire.wireplumber.package "wpctl"}"
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
