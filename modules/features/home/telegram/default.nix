_: {
  flake.homeModules.features-home-telegram =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        programs.noctalia.settings.theme.templates.community_ids = [ "telegram" ];

        home.packages = [ pkgs.telegram-desktop ];

        systemd.user.services = lib.mkGuiStartupService { package = pkgs.telegram-desktop; };
      };
    };
}
