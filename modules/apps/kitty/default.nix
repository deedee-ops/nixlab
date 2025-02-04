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

      keybindings = {
        "ctrl+equal" = "change_font_size all +1.0";
        "ctrl+plus" = "change_font_size all +1.0";
        "ctrl+kp_add" = "change_font_size all +1.0";
        "ctrl+minus" = "change_font_size all -1.0";
        "ctrl+kp_subtract" = "change_font_size all -1.0";
        "ctrl+0" = "change_font_size all 0";
      };

      settings = {
        confirm_os_window_close = 0;
        copy_on_select = true;
        cursor_shape = "block";
        disable_ligatures = "always";
        enable_audio_bell = false;
        scrollback_lines = config.myHomeApps.theme.terminalScrollBuffer;
        update_check_interval = 0;
        underline_hyperlinks = "never";
        window_padding_width = 6;
      };

      extraConfig = ''
        # ctrl+click for block selection
        mouse_map ctrl+left press ungrabbed mouse_selection rectangle

        # ctrl+click on links
        mouse_map left click ungrabbed mouse_handle_click prompt
        mouse_map ctrl+left click ungrabbed mouse_handle_click link
      '';
    };
  };
}
