_: {
  flake.homeModules.features-home-direnv = { pkgs, ... }: {
    config = {
      home.packages = [ pkgs.devenv ];

      programs.direnv = {
        enable = true;

        nix-direnv.enable = true;
      };
    };
  };
}
