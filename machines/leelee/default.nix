{ self, lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.leelee = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.leelee.config;

      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/incus.nix ];
      profileModules = [
        ./configuration.nix
      ];
    };

    deploy.nodes.leelee = lib.mkDeployConfig {
      system = "x86_64-linux";
      target = "leelee.home.arpa";
      sshUser = "ajgon";
      nixosConfig = flakePart.nixosConfigurations.leelee;
    };
  };
}
