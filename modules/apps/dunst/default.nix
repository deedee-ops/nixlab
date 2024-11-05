{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.dunst;
in
{
  options.myHomeApps.dunst = {
    enable = lib.mkEnableOption "dunst" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.dunst.enable = true;

    home.packages = [ pkgs.libnotify ];

    services.dunst = {
      enable = true;

      settings = {
        experiments = {
          per_monitor_dpi = "no";
        };

        global = {
          # theme
          default_icon = "${config.xdg.configHome}/dunst/default.png";
          icon_corner_radius = 0;
          frame_width = 3;
          corner_radius = 6;

          alignment = "left";
          always_run_script = true;
          browser = "${lib.getExe config.programs.firefox.package}";
          class = "Dunst";
          follow = "mouse";
          force_xinerama = false;
          format = "<b>%s</b>\n%b";
          hide_duplicate_count = false;
          history_length = 50;
          horizontal_padding = 10;
          icon_position = "left";
          idle_threshold = 120;
          ignore_newline = false;
          indicate_hidden = true;
          line_height = 5;
          markup = "full";
          max_icon_size = 64;
          monitor = 0;
          notification_height = 75;
          padding = 16;
          separator_height = 2;
          show_age_threshold = 60;
          show_indicators = true;
          shrink = false;
          sort = true;
          stack_duplicates = true;
          startup_notification = false;
          sticky_history = true;
          title = "Dunst";
          transparency = 0;
          word_wrap = true;

          # persistent
          timeout = 0;
          set_transient = false;
          ignore_dbusclose = true;

          # play sound
          script = "${config.xdg.configHome}/dunst/play-sound.sh";

          # geometry
          width = "(300, 500)";
          height = 175;
          origin = "top-right";
          notification_limit = 20;
          offset = "10x25";

          #shortcuts
          history = "ctrl+grave"; # ctrl+tilde
        };
      };
    };

    xdg.configFile = {
      "dunst/play-sound.sh" = {
        executable = true;
        text = ''
          #!${lib.getExe' pkgs.coreutils-full "env"} ${lib.getExe pkgs.bash}
          if [ ! -f /tmp/.dunst-mute ]; then
            ${lib.getExe' pkgs.pipewire "pw-play"} ${config.xdg.configHome}/dunst/pop.mp3
          fi
        '';
      };
      "dunst/default.png".source = ./default.png;
      "dunst/pop.mp3".source = ./pop.mp3;
    };
  };
}
