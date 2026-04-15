{ self, inputs, ... }:
{
  flake.nixosConfigurations.dexter = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.sops-nix.nixosModules.sops
      inputs.stylix.nixosModules.stylix

      self.nixosModules.hosts-dexter-configuration
    ];
  };
}
