_:
let
  commonThemeConfig =
    { pkgs, ... }:
    {
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        polarity = "dark";
        opacity.terminal = 0.95;
        # targets.font-packages.enable = true;
        #
        # cursor = {
        #   package = pkgs.catppuccin-cursors.mochaDark;
        #   name = "catppuccin-mocha-dark-cursors";
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
  flake.homeModules.themes-catppuccin =
    { pkgs, ... }:
    {
      config = { } // (commonThemeConfig { inherit pkgs; });
    };

  flake.nixosModules.themes-catppuccin =
    { pkgs, ... }:
    {
      config = { } // (commonThemeConfig { inherit pkgs; });
    };
}
