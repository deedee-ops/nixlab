{ lib, ... }:
rec {
  flakePart = {
    nixosConfigurations.piecyk = lib.mkNixosConfig {
      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/desktop.nix ];
      profileModules = [
        ./configuration.nix
      ];
    };
  };
}
