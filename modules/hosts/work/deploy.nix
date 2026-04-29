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
      hostname = "127.0.0.1";
      interactiveSudo = true;
      profiles.system = {
        sshUser = "ajgon";
        sshOpts = [
          "-p"
          "2222"
        ];
        remoteBuild = false;
        user = "root";
        path = inputs.deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations.work;
      };
    };
}
