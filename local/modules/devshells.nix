_: {
  perSystem =
    {
      config,
      pkgs,
      lib,
      inputs',
      ...
    }:
    {
      devShells.default = config.devShells.homelab;

      devShells.homelab = pkgs.mkShell {
        SOPS_AGE_KEY_FILE = "/persist/etc/age/keys.txt";

        nativeBuildInputs = [
          config.pre-commit.settings.package
          inputs'.deploy-rs.packages.default
          inputs'.lix.packages.default
          inputs'.nixos-anywhere.packages.default
        ];

        buildInputs = [
          pkgs.nh
          pkgs.nix-inspect
          pkgs.openssl
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}

          export GH_TOKEN="$(${lib.getExe pkgs.sops} -d --output-type json local/linters.sops.yaml | ${lib.getExe pkgs.jq} -r '.zizmor.GH_TOKEN')"

          ${lib.getExe pkgs.git} pull origin master:master --rebase
        '';
      };
    };
}
