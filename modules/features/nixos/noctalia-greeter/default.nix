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

              palette = {
                primary = "#cba6f7";
                on_primary = "#11111b";
                secondary = "#fab387";
                on_secondary = "#11111b";
                tertiary = "#94e2d5";
                on_tertiary = "#11111b";
                error = "#f38ba8";
                on_error = "#11111b";
                surface = "#1e1e2e";
                on_surface = "#cdd6f4";
                surface_variant = "#313244";
                on_surface_variant = "#a3b4eb";
                outline = "#4c4f69";
                shadow = "#11111b";
                hover = "#94e2d5";
                on_hover = "#11111b";
              };

              wallpaper = {
                path = "${../../../../assets/wallpapers/sddm.jpg}";
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
