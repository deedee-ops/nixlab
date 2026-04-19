_: {
  flake.homeModules.features-home-discord =
    { pkgs, lib, ... }:
    {
      config = {
        home.packages = [ pkgs.discord ];

        systemd.user.services = lib.mkGuiStartupService { package = pkgs.discord; };
      };
    };
}
