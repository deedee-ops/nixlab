_: {
  flake.homeModules.features-home-zathura = _: {
    config = {
      stylix.targets.zathura.enable = true;

      programs.zathura.enable = true;
    };
  };
}
