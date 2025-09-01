{ self, lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.meemee = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.meemee.config;

      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/desktop.nix ];
      profileModules = [
        ./configuration.nix
      ];
    };

    deploy.nodes.meemee = lib.mkDeployConfig {
      system = "x86_64-linux";
      target = "meemee.home.arpa";
      sshUser = "ajgon";
      nixosConfig = flakePart.nixosConfigurations.meemee;
    };
  };
}
