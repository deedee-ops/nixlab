_: {
  flake.homeModules.features-home-discord =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        stylix.targets.vesktop.enable = !config.programs.noctalia-shell.enable;
        programs.noctalia-shell.settings.templates.activeTemplates = [
          {
            enabled = true;
            id = "discord";
          }
        ];

        programs.vesktop = {
          enable = true;
          vencord.settings.enabledThemes = lib.optionals config.programs.noctalia-shell.enable [
            "noctalia-material.theme.css"
          ];
          settings = {
            discordBranch = "stable";
            minimizeToTray = false;
            arRPC = true;
          };
        };

        systemd.user.services = lib.mkGuiStartupService { package = pkgs.vesktop; };
      };
    };
}
