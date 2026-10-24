_: {
  flake.homeModules.features-home-bat = { config, ... }: {
    config = {
      stylix.targets.bat.enable = !config.programs.noctalia.enable;
      programs.noctalia.settings.theme.templates.community_ids = [ "bat" ];

      home.shellAliases = {
        cat = "bat";
      };

      programs.bat = {
        enable = true;

        config = {
          pager = "never";
          style = "plain";
        };
      };
    };
  };
}
