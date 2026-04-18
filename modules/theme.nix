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

            features.nixos.niri.noctalia.colors =
              if theme.polarity == "dark" then
                {
                  mPrimary = "#cba6f7";
                  mOnPrimary = "#11111b";
                  mSecondary = "#fab387";
                  mOnSecondary = "#11111b";
                  mTertiary = "#94e2d5";
                  mOnTertiary = "#11111b";
                  mError = "#f38ba8";
                  mOnError = "#11111b";
                  mSurface = "#1e1e2e";
                  mOnSurface = "#cdd6f4";
                  mSurfaceVariant = "#313244";
                  mOnSurfaceVariant = "#a3b4eb";
                  mOutline = "#4c4f69";
                  mShadow = "#11111b";
                  mHover = "#94e2d5";
                  mOnHover = "#11111b";
                }
              else
                {
                  mPrimary = "#8839ef";
                  mOnPrimary = "#eff1f5";
                  mSecondary = "#fe640b";
                  mOnSecondary = "#eff1f5";
                  mTertiary = "#40a02b";
                  mOnTertiary = "#eff1f5";
                  mError = "#d20f39";
                  mOnError = "#dce0e8";
                  mSurface = "#eff1f5";
                  mOnSurface = "#4c4f69";
                  mSurfaceVariant = "#ccd0da";
                  mOnSurfaceVariant = "#6c6f85";
                  mOutline = "#a5adcb";
                  mShadow = "#dce0e8";
                  mHover = "#40a02b";
                  mOnHover = "#eff1f5";
                };
          }
          // (commonThemeConfig { inherit pkgs theme; });
      };
  };
}
