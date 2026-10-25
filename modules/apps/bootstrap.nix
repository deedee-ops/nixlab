{ self, ... }:
{
  perSystem =
    {
      inputs',
      pkgs,
      lib,
      ...
    }:
    {
      apps.bootstrap = {
        type = "app";
        program = pkgs.writeShellApplication {
          name = "bootstrap";
          runtimeInputs = [
            inputs'.nixos-anywhere.packages.default
            pkgs.sops
            pkgs.yq-go
          ];
          text = ''
            ${lib.join "\n" (
              lib.mapAttrsToList (name: host: ''
                export SOPS_${name}="${host.config.sops.defaultSopsFile}"
                export CA_BUNDLE_${name}="${host.config.security.pki.caBundle}"
              '') self.nixosConfigurations
            )}

            ${builtins.readFile ./bootstrap.sh}
          '';
        };
      };
    };
}
