{ self, inputs, ... }:
{
  flake.nixosModules.features-nixos-noctalia-greeter =
    { config, pkgs, ... }:
    let
      cursorTheme = "catppuccin-${self.theme.style}-${self.theme.polarity}-cursors";
      cursorPackage =
        pkgs.catppuccin-cursors."${self.theme.style}${
          if self.theme.polarity == "dark" then "Dark" else "Light"
        }";
    in
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      config = {
        services.displayManager.noctalia-greeter = {
          enable = true;

          settings = {
            session.default = "Niri";

            appearance = {
              scheme = "Synced";
              theme_mode = "dark";
              font_family = "sans-serif";

              # base16 has no crust (#11111b) and no matches for the two greys, those stay literal
              palette = with config.lib.stylix.colors.withHashtag; {
                primary = base0E;
                on_primary = "#11111b";
                secondary = base09;
                on_secondary = "#11111b";
                tertiary = base0C;
                on_tertiary = "#11111b";
                error = base08;
                on_error = "#11111b";
                surface = base00;
                on_surface = base05;
                surface_variant = base01;
                on_surface_variant = "#a3b4eb";
                outline = "#4c4f69";
                shadow = "#11111b";
                hover = base0C;
                on_hover = "#11111b";
              };

              wallpaper = {
                path = "${inputs.wallpapers}/greeter.jpg";
                fill_mode = "crop";
              };
            };

            cursor = {
              theme = cursorTheme;
              size = 24;
              path = "${cursorPackage}/share/icons";
            };

            keyboard = {
              inherit (config.services.xserver.xkb) layout variant;
            };
          };
        };
      };
    };
}
