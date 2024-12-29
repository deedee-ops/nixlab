{ self, lib, ... }:
{
  flakePart = {
    nixosConfigurations.piecyk = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.piecyk.config;

      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/desktop.nix ];
      profileModules = [
        ./configuration.nix
      ];
    };
  };
}
