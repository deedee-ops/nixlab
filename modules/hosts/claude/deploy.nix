{
  self,
  inputs,
  ...
}:
{
  flake.deploy.nodes.claude =
    let
      inherit (self.nixosConfigurations.claude.config.nixpkgs.hostPlatform) system;
    in
    {
      hostname = "claude.internal";
      # wheel has passwordless sudo on this host
      interactiveSudo = false;
      profiles.system = {
        sshUser = "ajgon";
        remoteBuild = false;
        user = "root";
        path = inputs.deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations.claude;
      };
    };
}
