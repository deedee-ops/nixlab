{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.alacritty;
in
{
  options.myHomeApps.alacritty = {
    enable = lib.mkEnableOption "alacritty";
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.alacritty.enable = true;

    programs.alacritty = {
      enable = true;

      settings = {
        env = {
          LC_ALL = osConfig.i18n.defaultLocale;
          TERM = "xterm-256color";
        };

        scrolling = {
          history = config.myHomeApps.theme.terminalScrollBuffer;
        };

        selection = {
          save_to_clipboard = true;
        };

        terminal = {
          shell = {
            program = "${pkgs.zsh}/bin/zsh";
          };
        };

        window = {
          padding = {
            x = 6;
            y = 6;
          };
          title = "Alacritty";
        };
      };
    };
  };
}
