{ lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.meemee = lib.mkNixosConfig {
      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/wyse-5070.nix ];
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
