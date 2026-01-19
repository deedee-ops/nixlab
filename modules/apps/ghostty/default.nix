{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.ghostty;
in
{
  options.myHomeApps.ghostty = {
    enable = lib.mkEnableOption "ghostty";
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;

      package = pkgs.ghostty.overrideAttrs (oldAttrs: {
        zigBuildFlags = oldAttrs.zigBuildFlags ++ [ "-Dsentry=false" ];
      });

      settings = {
        theme = "Catppuccin Mocha";
        background-opacity = config.stylix.opacity.terminal;
        font-size = config.stylix.fonts.sizes.terminal;
        font-family = config.stylix.fonts.monospace.name;
        window-decoration = "none";
        gtk-single-instance = true;
        window-inherit-working-directory = false;
        working-directory = "home";

        scrollback-limit = config.myHomeApps.theme.terminalScrollBuffer;
        confirm-close-surface = false;
        copy-on-select = "clipboard";
        clipboard-trim-trailing-spaces = true;
        shell-integration = "zsh";
        shell-integration-features = "no-cursor,sudo";
        cursor-style = "block";
        font-feature = [
          "-calt"
          "-liga"
          "-dlig"
        ]; # disable ligatures
        window-padding-x = 6;
        window-padding-y = 6;

        auto-update = "off";

        keybind = [
          "shift+insert=paste_from_clipboard"
        ];
      };
    };
  };
}
