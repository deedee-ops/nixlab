_: {
  flake.nixosModules.features-nixos-sddm =
    { pkgs, ... }:
    {
      config =
        let
          sddm-astrounaut-theme = pkgs.sddm-astronaut.override { embeddedTheme = "black_hole"; };
        in
        {
          services.displayManager = {
            sddm = {
              enable = true;
              wayland.enable = true;
              theme = "sddm-astronaut-theme";
              extraPackages = [
                sddm-astrounaut-theme
                pkgs.kdePackages.qtmultimedia
                pkgs.kdePackages.qtsvg
                pkgs.kdePackages.qtvirtualkeyboard
              ];
              settings = {
                General = {
                  GreeterEnvironment = "QT_SCREEN_SCALE_FACTORS=1.5";
                };
              };
            };

            defaultSession = "niri";
          };

          environment.systemPackages = [ sddm-astrounaut-theme ];
        };
    };
}
