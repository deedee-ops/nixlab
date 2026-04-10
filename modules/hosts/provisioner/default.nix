{ self, inputs, ... }: {
  flake.nixosConfigurations.provisioner = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      self.nixosModules.hosts-provisioner-configuration
    ];
  };
}
