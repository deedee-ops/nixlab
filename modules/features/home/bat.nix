_: {
  flake.homeModules.features-home-bat = _: {
    config = {
      stylix.targets.bat.enable = true;

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
