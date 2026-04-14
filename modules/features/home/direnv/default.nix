_: {
  flake.homeModules.features-home-direnv = _: {
    config = {
      programs.direnv = {
        enable = true;

        nix-direnv.enable = true;
      };
    };
  };
}
