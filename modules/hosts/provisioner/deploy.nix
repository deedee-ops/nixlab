{
  self,
  inputs,
  ...
}:
{
  flake.deploy.nodes.provisioner =
    let
      inherit (self.nixosConfigurations.provisioner.config.nixpkgs.hostPlatform) system;
    in
    {
      hostname = "192.168.2.104";
      interactiveSudo = true;
      profiles.system = {
        sshUser = "ajgon";
        remoteBuild = false;
        user = "root";
        path = inputs.deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations.provisioner;
      };
    };
}
