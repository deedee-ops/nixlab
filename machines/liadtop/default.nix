{ self, lib, ... }:
{
  flakePart = {
    nixosConfigurations.liadtop = lib.mkNixosConfig {
      osConfig = self.nixosConfigurations.liadtop.config;

      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/zenbook-14.nix ];
      profileModules = [
        ./configuration.nix
      ];
    };
  };
}
