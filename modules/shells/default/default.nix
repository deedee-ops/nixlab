_: {
  perSystem =
    {
      inputs',
      lib,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
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
          export SOPS_AGE_SSH_PRIVATE_KEY_FILE=/run/secrets/credentials/ssh/private_key

          ${lib.getExe pkgs.git} fetch --all
        '';
      };
    };
}
