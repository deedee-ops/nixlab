_:
let
  commonThemeConfig =
    { pkgs, theme, ... }:
    {
      stylix = {
        inherit (theme) polarity;

        enable = true;
        autoEnable = false;
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
      capitalizedName = "Catppuccin";
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
