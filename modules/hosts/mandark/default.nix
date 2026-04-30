{ self, inputs, ... }:
{
  flake.nixosConfigurations.mandark = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.sops-nix.nixosModules.sops
      inputs.stylix.nixosModules.stylix

      self.nixosModules.hosts-mandark-configuration
    ];
  };
}
