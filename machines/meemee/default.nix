{ self, lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.meemee = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.meemee.config;

      system = "aarch64-linux";
      hardwareModules = [
        ../../modules/hardware/raspberry-pi-4b.nix
      ];
      profileModules = [
        ./configuration.nix
      ];
    };

    deploy.nodes.meemee = lib.mkDeployConfig {
      system = "aarch64-linux";
      target = "meemee.home.arpa";
      sshUser = "ajgon";
      nixosConfig = flakePart.nixosConfigurations.meemee;
    };
  };
}
