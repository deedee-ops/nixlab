{
  inputs,
  config,
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
      (inputs.ghostty.packages.x86_64-linux.ghostty.overrideAttrs (oldAttrs: {
        patches = [
          ./no-sentry.patch
        ];
        zigBuildFlags = oldAttrs.zigBuildFlags + " -Dsentry=false";
      }))
    ];

    programs.zsh = {
      initExtra = ''
        if [[ "$TERM" == "xterm-ghostty" ]] && [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
          unalias sudo 2> /dev/null
          source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
        fi
      '';
    };

    xdg.configFile = {
      "ghostty/config".text = toGhosttyConfig {
        theme = "catppuccin-mocha";
        background-opacity = config.stylix.opacity.terminal;
        font-size = config.stylix.fonts.sizes.terminal;
        font-family = config.stylix.fonts.monospace.name;
        window-decoration = false;
        gtk-single-instance = true;
        gtk-adwaita = false;

        scrollback-limit = 5000;
        confirm-close-surface = false;
        copy-on-select = "clipboard";
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
