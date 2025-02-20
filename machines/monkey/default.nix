{ self, lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.monkey = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.monkey.config;

      system = "x86_64-linux";
      hardwareModules = [
        ../../modules/hardware/nuc8.nix
      ];
      profileModules = [
        ./configuration.nix
      ];
    };

    deploy.nodes.monkey = lib.mkDeployConfig {
      system = "x86_64-linux";
      target = "monkey.home.arpa";
      sshUser = "ajgon";
      nixosConfig = flakePart.nixosConfigurations.monkey;
    };
  };
}
