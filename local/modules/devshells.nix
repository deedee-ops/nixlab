_: {
  perSystem =
    {
      config,
      pkgs,
      inputs',
      ...
    }:
    {
      devShells.default = config.devShells.homelab;

      devShells.homelab = pkgs.mkShell {
        nativeBuildInputs = [
          config.pre-commit.settings.package
          inputs'.lix.packages.default
          inputs'.deploy-rs.packages.default
          inputs'.nixos-anywhere.packages.default
        ];

        buildInputs = [
          pkgs.nh
          pkgs.openssl
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
}
