{ lib, ... }:
{
  flakePart = {
    nixosConfigurations.liadtop = lib.mkNixosConfig {
      system = "x86_64-linux";
      hardwareModules = [ ../../modules/hardware/zenbook-14.nix ];
      profileModules = [
        ./configuration.nix
      ];
    };
  };
}
