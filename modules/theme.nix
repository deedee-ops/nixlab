_:
let
  commonThemeConfig =
    { pkgs, theme, ... }:
    {
      stylix = {
        inherit (theme) polarity;

        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${theme.name}-${theme.style}.yaml";
        opacity.terminal = 0.95;
        # targets.font-packages.enable = true;
        #
        # cursor = {
        #   package = pkgs.catppuccin-cursors."${theme.style}Dark";
        #   name = "catppuccin-${theme.style}-dark-cursors";
        #   size = 48;
        # };
        #
        # fonts = {
        #   serif = {
        #     package = pkgs.noto-fonts;
        #     name = "Noto Serif";
        #   };
        #
        #   sansSerif = {
        #     package = pkgs.noto-fonts;
        #     name = "Noto Sans";
        #   };
        #
        #   monospace = {
        #     package = pkgs.nerd-fonts.jetbrains-mono;
        #     name = "JetBrainsMono Nerd Font Mono";
        #   };
        #
        #   emoji = {
        #     package = pkgs.noto-fonts-color-emoji;
        #     name = "Noto Color Emoji";
        #   };
        # };
      };
    };
in
{
  flake = rec {
    theme = {
      name = "catppuccin";
      style = "mocha";
      polarity = "dark";
    };

    homeModules.theme =
      { pkgs, ... }:
      {
        config = {
        }
        // (commonThemeConfig { inherit pkgs theme; });
      };

    nixosModules.theme =
      { pkgs, ... }:
      {
        config = {
        }
        // (commonThemeConfig { inherit pkgs theme; });
      };
  };
}
