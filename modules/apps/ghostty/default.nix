{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.ghostty;

  toGhosttyConfig = lib.generators.toKeyValue {
    mkKeyValue =
      key: value:
      if builtins.isList value then
        builtins.concatStringsSep "\n" (builtins.map (v: "${key} = ${v}") value)
      else
        "${key} = ${
          if builtins.isBool value then (if value then "true" else "false") else (builtins.toString value)
        }";
  };
in
{
  options.myHomeApps.ghostty = {
    enable = lib.mkEnableOption "ghostty";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.ghostty.overrideAttrs (oldAttrs: {
        zigBuildFlags = oldAttrs.zigBuildFlags + " -Dsentry=false";
      }))
    ];

    xdg.configFile = {
      "ghostty/config".text = toGhosttyConfig {
        theme = "catppuccin-mocha";
        background-opacity = config.stylix.opacity.terminal;
        font-size = config.stylix.fonts.sizes.terminal;
        font-family = config.stylix.fonts.monospace.name;
        window-decoration = false;
        gtk-single-instance = true;
        gtk-adwaita = false;

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
      };
    };
  };
}
