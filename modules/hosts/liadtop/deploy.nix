{
  self,
  inputs,
  ...
}:
{
  flake.deploy.nodes.liadtop =
    let
      inherit (self.nixosConfigurations.liadtop.config.nixpkgs.hostPlatform) system;
    in
    {
      hostname = "liadtop.internal";
      interactiveSudo = true;
      profiles.system = {
        sshUser = "ajgon";
        remoteBuild = false;
        user = "root";
        path = inputs.deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations.liadtop;
      };
    };
}
