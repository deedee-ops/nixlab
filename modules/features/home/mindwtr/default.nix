{ self, ... }: {
  flake.homeModules.features-home-mindwtr = { pkgs, ... }: {
    home.packages = [ self.packages."${pkgs.stdenv.hostPlatform.system}".mindwtr ];
  };

  perSystem =
    { pkgs, ... }:
    {
      packages.mindwtr = pkgs.callPackage ./package.nix { };
    };
}
