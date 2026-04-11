_: {
  perSystem =
    {
      inputs',
      config,
      lib,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          config.pre-commit.settings.package
          inputs'.deploy-rs.packages.default
          inputs'.nixos-anywhere.packages.default
        ];

        buildInputs = [
          pkgs.nh
          pkgs.nix-inspect
          pkgs.nix-output-monitor
          pkgs.sops
          pkgs.yq-go
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}

          export SOPS_AGE_SSH_PRIVATE_KEY_FILE=/run/secrets/credentials/ssh/private_key

          ${lib.getExe pkgs.git} fetch --all
        '';
      };
    };
}
