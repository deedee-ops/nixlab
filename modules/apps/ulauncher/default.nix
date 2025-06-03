{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.ulauncher;
in
{
  options.myHomeApps.ulauncher = {
    enable = lib.mkEnableOption "ulauncher";
  };

  config = lib.mkIf cfg.enable {
    myHomeApps.awesome = {
      autorun = [ "${(lib.getExe pkgs.ulauncher)} --hide-window" ];
      awfulRules = [
        {
          rule = {
            class = "Ulauncher";
          };
          properties = {
            border_width = 0;
            floating = true;
            ontop = true;
            skip_taskbar = true;
          };
        }
      ];
    };

    xdg.configFile = {
      "ulauncher/user-themes" = {
        source = ./user-themes;
        recursive = true;
      };

      "ulauncher/settings.json".text = builtins.toJSON {
        blacklisted-desktop-dirs = builtins.concatStringsSep ":" [
          "/usr/share/locale"
          "/usr/share/app-install"
          "/usr/share/kservices5"
          "/usr/share/fk5"
          "/usr/share/kservicetypes5"
          "/usr/share/applications/screensavers"
          "/usr/share/kde4"
          "/usr/share/mimelnk"
        ];

        clear-previous-query = true;
        disable-desktop-filters = false;
        grab-mouse-pointer = false;
        hotkey-show-app = "<Primary>space";
        # hotkey-show-app = "<Super>space";
        render-on-screen = "mouse-pointer-monitor";
        show-indicator-icon = true;
        show-recent-apps = "0";
        terminal-command = "${lib.getExe config.myHomeApps.xorg.terminal}";
        theme-name = "Catppuccin-Mocha-Blue";
      };
    };
  };
}
