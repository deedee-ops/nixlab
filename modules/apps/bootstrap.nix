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
              lib.mapAttrsToList (
                name: _value:
                "export SOPS_${name}=\"${self.nixosConfigurations."${name}".config.sops.defaultSopsFile}\""
              ) self.nixosConfigurations
            )}

            ${builtins.readFile ./bootstrap.sh}
          '';
        };
      };
    };
}
