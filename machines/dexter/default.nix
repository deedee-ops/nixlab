{ self, lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.dexter = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.dexter.config;

      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/nuc12.nix ];
      profileModules = [
        ./configuration.nix
      ];
    };

    deploy.nodes.dexter = lib.mkDeployConfig {
      system = "x86_64-linux";
      target = "dexter.home.arpa";
      sshUser = "ajgon";
      nixosConfig = flakePart.nixosConfigurations.dexter;
    };
  };
}
