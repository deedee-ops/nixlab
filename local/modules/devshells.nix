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
          inputs'.nixos-anywhere.packages.default
        ];

        buildInputs = [
          pkgs.nh
          pkgs.nix-inspect
          pkgs.nix-output-monitor
          pkgs.openssl
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}

          export GH_TOKEN="$(${lib.getExe pkgs.sops} -d --output-type json local/secrets.sops.yaml | ${lib.getExe pkgs.jq} -r '.zizmor.GH_TOKEN')"
          export AWS_SECRET_ACCESS_KEY="$(${lib.getExe pkgs.sops} -d --output-type json local/secrets.sops.yaml | ${lib.getExe pkgs.jq} -r '.nixcache.AWS_SECRET_ACCESS_KEY')"
          export AWS_ACCESS_KEY_ID="$(${lib.getExe pkgs.sops} -d --output-type json local/secrets.sops.yaml | ${lib.getExe pkgs.jq} -r '.nixcache.AWS_ACCESS_KEY_ID')"
          export NIXCACHE_PRIVATE_KEY="$(${lib.getExe pkgs.sops} -d --output-type json local/secrets.sops.yaml | ${lib.getExe pkgs.jq} -r '.nixcache.NIXCACHE_PRIVATE_KEY')"
          export NIXCACHE_PUBLIC_KEY="$(${lib.getExe pkgs.sops} -d --output-type json local/secrets.sops.yaml | ${lib.getExe pkgs.jq} -r '.nixcache.NIXCACHE_PUBLIC_KEY')"

          ${lib.getExe pkgs.git} pull origin master:master --rebase
          ${lib.getExe pkgs.git} fetch --all
        '';
      };
    };
}
