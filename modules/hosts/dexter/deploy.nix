{
  self,
  inputs,
  ...
}:
{
  flake.deploy.nodes.dexter =
    let
      inherit (self.nixosConfigurations.dexter.config.nixpkgs.hostPlatform) system;
    in
    {
      hostname = "dexter.internal";
      interactiveSudo = true;
      profiles.system = {
        sshUser = "ajgon";
        remoteBuild = false;
        user = "root";
        path = inputs.deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations.dexter;
      };
    };
}
