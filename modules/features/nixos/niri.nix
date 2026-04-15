{ self, inputs, ... }:
{
  flake.nixosModules.features-nixos-niri =
    { pkgs, ... }:
    {
      # services.greetd = {
      #   enable = true;
      #   settings = {
      #     default_session = {
      #       command = "niri-session";
      #       user = "ajgon";
      #     };
      #   };
      # };

      programs.niri = {
        enable = true;
        package = self.packages."${pkgs.stdenv.hostPlatform.system}".niri;
      };
    };

  perSystem =
    { pkgs, lib, ... }:
    {
      packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          input.keyboard = {
            xkb.layout = "us,pl";
          };

          layout.gaps = 5;

          binds = {
            "Mod+Return".spawn-sh = lib.getExe pkgs.alacritty;
            "Mod+Q".close-window = null;
          };
        };
      };
    };
}
