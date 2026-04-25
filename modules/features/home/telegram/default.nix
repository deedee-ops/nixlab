_: {
  flake.homeModules.features-home-telegram =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        programs.noctalia-shell.settings.templates.activeTemplates = [
          {
            enabled = true;
            id = "telegram";
          }
        ];

        home.packages = [ pkgs.telegram-desktop ];

        systemd.user.services = lib.mkGuiStartupService { package = pkgs.telegram-desktop; };
      };
    };
}
