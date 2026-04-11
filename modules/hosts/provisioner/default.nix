{ self, inputs, ... }:
{
  flake.nixosConfigurations.provisioner = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      inputs.nix-index-database.nixosModules.nix-index
      inputs.sops-nix.nixosModules.sops

      self.nixosModules.hosts-provisioner-configuration
    ];
  };
}
