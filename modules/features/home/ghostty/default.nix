{ self, ... }:
{
  flake.homeModules.features-home-ghostty =
    { config, pkgs, ... }:
    {
      config = {
        programs.ghostty = {
          enable = true;
          package = self.packages."${pkgs.stdenv.hostPlatform.system}".ghostty;

          settings = {
            theme = "Catppuccin Mocha";
            background-opacity = config.stylix.opacity.terminal;
            font-size = config.stylix.fonts.sizes.terminal;
            font-family = config.stylix.fonts.monospace.name;
            window-decoration = "none";
            gtk-single-instance = true;
            window-inherit-working-directory = false;
            working-directory = "home";

            scrollback-limit = 16777216; # 16 megabytes
            confirm-close-surface = false;
            copy-on-select = "clipboard";
            clipboard-trim-trailing-spaces = true;
            shell-integration = "zsh";
            shell-integration-features = "no-cursor,sudo";
            cursor-style = "block";
            font-feature = [
              "-calt"
              "-liga"
              "-dlig"
            ]; # disable ligatures
            window-padding-x = 6;
            window-padding-y = 6;

            auto-update = "off";

            keybind = [
              "shift+insert=paste_from_clipboard"
            ];
          };
        };
      };
    };
  perSystem =
    { pkgs, ... }:
    {
      packages.ghostty = pkgs.ghostty.overrideAttrs (oldAttrs: {
        zigBuildFlags = oldAttrs.zigBuildFlags ++ [ "-Dsentry=false" ];
      });
    };
}
