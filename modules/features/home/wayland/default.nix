{ self, ... }:
{
  flake.homeModules.features-home-wayland =
    { pkgs, lib, ... }:
    {
      config =
        let
          cursorTheme = "catppuccin-${self.theme.style}-${self.theme.polarity}-cursors";
          cursorPackage =
            pkgs.catppuccin-cursors."${self.theme.style}${
              if self.theme.polarity == "dark" then "Dark" else "Light"
            }";
          cursorSize = 24;
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

          qt.platformTheme.name = lib.mkForce "gtk3";
        };
    };
}
