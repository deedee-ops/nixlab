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

    home.shellAliases.ssh = "${lib.getExe' config.programs.kitty.package "kitten"} ssh";

    programs.kitty = {
      enable = true;
      shellIntegration = {
        mode = "no-cursor";
        enableZshIntegration = true;
      };

      environment = {
        LC_ALL = osConfig.i18n.defaultLocale;
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
