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

          ${lib.getExe pkgs.git} pull origin master:master --rebase
        '';
      };
    };
}
