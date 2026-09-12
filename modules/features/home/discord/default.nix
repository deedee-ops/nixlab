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
        stylix.targets.vesktop.enable = !config.programs.noctalia.enable;
        programs.noctalia.settings.theme.templates.community_ids = [ "discord" ];

        programs.vesktop = {
          enable = true;
          vencord.settings.enabledThemes = lib.optionals config.programs.noctalia.enable [
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
