{ self, inputs, ... }:
{
  flake.nixosConfigurations.liadtop = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.sops-nix.nixosModules.sops
      inputs.stylix.nixosModules.stylix

      self.nixosModules.hosts-liadtop-configuration
      self.nixosModules.hosts-liadtop-devices
    ];
  };
}
