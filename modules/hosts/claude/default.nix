{ self, inputs, ... }:
{
  flake.nixosConfigurations.claude = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.sops-nix.nixosModules.sops
      inputs.stylix.nixosModules.stylix

      self.nixosModules.hosts-claude-claude
      self.nixosModules.hosts-claude-configuration
    ];
  };
}
