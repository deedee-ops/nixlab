{
  config,
  osConfig,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.kitty;
in
{
  options.myHomeApps.kitty = {
    enable = lib.mkEnableOption "kitty";
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.kitty.enable = true;

    programs.kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;

      environment = {
        LC_ALL = osConfig.i18n.defaultLocale;
        TERM = "xterm-256color";
      };

      font.size = 12;

      settings = {
        copy_on_select = true;
        cursor_shape = "block";
        enable_audio_bell = false;
        update_check_interval = 0;
        window_padding_width = 6;
      };
    };
  };
}
