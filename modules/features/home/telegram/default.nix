_: {
  flake.homeModules.features-home-telegram =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        home.packages = [ pkgs.telegram-desktop ];

        systemd.user.services = lib.mkGuiStartupService { package = pkgs.telegram-desktop; };
      };
    };
}
