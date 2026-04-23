{
  self,
  inputs,
  ...
}:
{
  flake.deploy.nodes.work =
    let
      inherit (self.nixosConfigurations.work.config.nixpkgs.hostPlatform) system;
    in
    {
      hostname = "work.internal";
      interactiveSudo = true;
      profiles.system = {
        sshUser = "ajgon";
        remoteBuild = false;
        user = "root";
        path = inputs.deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations.work;
      };
    };
}
