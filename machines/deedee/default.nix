{ self, lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.deedee = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.deedee.config;

      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/nuc12.nix ];
      profileModules = [
        ./configuration.nix
      ];
    };

    deploy.nodes.deedee = lib.mkDeployConfig {
      system = "x86_64-linux";
      target = "deedee.home.arpa";
      sshUser = "ajgon";
      nixosConfig = flakePart.nixosConfigurations.deedee;
    };
  };
}
