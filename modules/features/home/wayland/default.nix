{ self, ... }:
{
  flake.homeModules.features-home-wayland =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      config =
        let
          cursorTheme = "catppuccin-${self.theme.style}-${self.theme.polarity}-cursors";
          cursorPackage =
            pkgs.catppuccin-cursors."${self.theme.style}${
              if self.theme.polarity == "dark" then "Dark" else "Light"
            }";
          cursorSize = 24;

          colors = config.lib.stylix.colors;
          rgb = name: "${colors."${name}-rgb-r"},${colors."${name}-rgb-g"},${colors."${name}-rgb-b"}";
          colorGroup =
            {
              bg,
              bgAlt,
              fg,
              fgInactive ? rgb "base04",
            }:
            ''
              BackgroundNormal=${bg}
              BackgroundAlternate=${bgAlt}
              ForegroundNormal=${fg}
              ForegroundInactive=${fgInactive}
              ForegroundActive=${rgb "base0D"}
              ForegroundLink=${rgb "base0D"}
              ForegroundVisited=${rgb "base0E"}
              ForegroundNegative=${rgb "base08"}
              ForegroundNeutral=${rgb "base0A"}
              ForegroundPositive=${rgb "base0B"}
              DecorationFocus=${rgb "base0D"}
              DecorationHover=${rgb "base0D"}
            '';
        in
        {
          home = {
            packages = [ cursorPackage ];

            pointerCursor = {
              name = cursorTheme;
              package = cursorPackage;
              dotIcons.enable = false;
              size = cursorSize;
              gtk.enable = true;
              x11.enable = false;
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
              name = "Papirus-${if self.theme.polarity == "dark" then "Dark" else "Light"}";
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

          xdg.configFile."kdeglobals".text = ''
            [General]
            ColorScheme=${self.theme.capitalizedName}${self.theme.style}
            Name=${self.theme.capitalizedName} ${self.theme.style}

            [KDE]
            widgetStyle=Breeze

            [Colors:Window]
            ${colorGroup {
              bg = rgb "base00";
              bgAlt = rgb "base01";
              fg = rgb "base05";
            }}
            [Colors:View]
            ${colorGroup {
              bg = rgb "base00";
              bgAlt = rgb "base01";
              fg = rgb "base05";
            }}
            [Colors:Button]
            ${colorGroup {
              bg = rgb "base02";
              bgAlt = rgb "base03";
              fg = rgb "base05";
            }}
            [Colors:Selection]
            ${colorGroup {
              bg = rgb "base0D";
              bgAlt = rgb "base0D";
              fg = rgb "base00";
              fgInactive = rgb "base01";
            }}
            [Colors:Tooltip]
            ${colorGroup {
              bg = rgb "base01";
              bgAlt = rgb "base02";
              fg = rgb "base05";
            }}
            [Colors:Complementary]
            ${colorGroup {
              bg = rgb "base01";
              bgAlt = rgb "base02";
              fg = rgb "base05";
            }}
            [WM]
            activeBackground=${rgb "base00"}
            activeForeground=${rgb "base05"}
            inactiveBackground=${rgb "base01"}
            inactiveForeground=${rgb "base04"}

            [KFileDialog Settings]
            Show Preview=true
            Preview Width=240
            Show Inline Previews=true
            Places Icons Auto-resize=false
            Places Icons Static Size=22
          '';

          qt.platformTheme.name = lib.mkForce "kde";
        };
    };
}
