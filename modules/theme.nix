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
        targets.font-packages.enable = true;

        fonts = {
          serif = {
            package = pkgs.noto-fonts;
            name = "Noto Serif";
          };

          sansSerif = {
            package = pkgs.noto-fonts;
            name = "Noto Sans";
          };

          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
          };

          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };
    };
in
{
  flake = rec {
    theme = {
      name = "catppuccin";
      style = "mocha";
      accent = "blue";
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
        config =
          let
            grubTheme = pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "grub";
              rev = "v1.0.0";
              sha256 = "sha256-/bSolCta8GCZ4lP0u5NVqYQ9Y3ZooYCNdTwORNvR7M0=";
            };
          in
          {
            boot = {
              loader.grub.theme = "${grubTheme}/src/catppuccin-${theme.style}-grub-theme";

              plymouth = {
                theme = "catppuccin-${theme.style}";
                themePackages = [ (pkgs.catppuccin-plymouth.override { variant = theme.style; }) ];
              };
            };
          }
          // (commonThemeConfig { inherit pkgs theme; });
      };
  };
}
