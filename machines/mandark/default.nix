{ self, lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.mandark = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.mandark.config;

      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/digitalocean.nix ];
      profileModules = [
        ./configuration.nix
        ./networking.nix
      ];
    };

    deploy.nodes.mandark = lib.mkDeployConfig {
      system = "x86_64-linux";
      target = "relay.rzegocki.dev";
      sshUser = "ajgon";
      nixosConfig = flakePart.nixosConfigurations.mandark;
      remoteBuild = false;
    };
  };
}
