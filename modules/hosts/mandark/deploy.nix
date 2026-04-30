{
  self,
  inputs,
  ...
}:
{
  flake.deploy.nodes.mandark =
    let
      inherit (self.nixosConfigurations.mandark.config.nixpkgs.hostPlatform) system;
      initialDeploy = false;
    in
    {
      # hostname = "relay.rzegocki.dev";
      hostname = "92.243.24.89";
      interactiveSudo = !initialDeploy;
      profiles.system = {
        sshUser = if initialDeploy then "root" else "ajgon";
        # Initial deployment as root is expected to throw error,
        # due to dbus shenaningans, but deploy itself is fine.
        # With magic rollback enabled, this perfectly fine deploy
        # will be reverted.
        # Subsequential deployments as normal user, are fine as
        # dbus will behave properly on unprivileged user.
        magicRollback = !initialDeploy;
        remoteBuild = false;
        user = "root";
        path = inputs.deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations.mandark;
      };
    };
}
