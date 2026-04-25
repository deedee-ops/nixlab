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
      { pkgs, lib, ... }:
      {
        config =
          let
            cursorTheme = "catppuccin-${theme.style}-${theme.polarity}-cursors";
            cursorPackage =
              pkgs.catppuccin-cursors."${theme.style}${if theme.polarity == "dark" then "Dark" else "Light"}";
            cursorSize = 24;
          in
          {
            home = {
              packages = [ cursorPackage ];

              pointerCursor = {
                name = cursorTheme;
                package = cursorPackage;
                size = cursorSize;
                gtk.enable = true;
                x11.enable = true;
              };
            };

            gtk = {
              enable = true;
              cursorTheme = {
                name = cursorTheme;
                package = cursorPackage;
                size = cursorSize;
              };
              iconTheme = {
                name = "Papirus-${if theme.polarity == "dark" then "Dark" else "Light"}";
                package = pkgs.papirus-icon-theme;
              };
            };

            dconf.settings."org/gnome/desktop/interface" = {
              cursor-theme = cursorTheme;
              cursor-size = cursorSize;
            };

            home.sessionVariables = {
              XCURSOR_THEME = cursorTheme;
              XCURSOR_SIZE = toString cursorSize;
              HYPRCURSOR_THEME = cursorTheme;
              HYPRCURSOR_SIZE = toString cursorSize;
            };

            xdg.dataFile."icons/${cursorTheme}".source = "${cursorPackage}/share/icons/${cursorTheme}";

            qt.platformTheme.name = lib.mkForce "gtk3";
          }
          // (commonThemeConfig { inherit pkgs theme; });
      };

    nixosModules.theme =
      { options, pkgs, ... }:
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

            features.nixos =
              if (options ? features && options.features ? nixos && options.features.nixos ? niri) then
                {
                  niri.noctalia = {
                    colors =
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
                    extraSettings = {
                      cursor = {
                        theme = "catppuccin-${theme.style}-${theme.polarity}-cursors";
                        size = 24;
                      };
                      layout = {
                        focus-ring = {
                          active-color = "#cba6f7";
                          inactive-color = "#1e1e2e";
                          urgent-color = "#f38ba8";
                        };
                        border = {
                          active-color = "#cba6f7";
                          inactive-color = "#1e1e2e";
                          urgent-color = "#f38ba8";
                        };

                        shadow = {
                          color = "#11111b70";
                        };

                        tab-indicator = {
                          active-color = "#cba6f7";
                          inactive-color = "#6b02e9";
                          urgent-color = "#f38ba8";
                        };

                        insert-hint = {
                          color = "#cba6f780";
                        };
                      };

                      recent-windows = {
                        highlight = {
                          active-color = "#cba6f7";
                          urgent-color = "#f38ba8";
                        };
                      };
                    };
                  };
                }
              else
                { };
          }
          // (commonThemeConfig { inherit pkgs theme; });
      };
  };
}
