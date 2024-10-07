{
  self,
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [ ./deedee ];

  options = {
    flakePart = {
      nixosConfigurations = lib.mkOption {
        type = lib.types.attrs;
        description = "Set of nixosconfigurations for the flake.";
      };
      deploy.nodes = lib.mkOption {
        type = lib.types.attrs;
        description = "Set of deploy nodes for the flake.";
      };
    };
  };

  config = {
    flake =
      {
        checks = builtins.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;

        nixosVMs.base = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${inputs.nixpkgs}/nixos/modules/virtualisation/lxd-virtual-machine.nix"
            (_: {
              services.openssh = {
                enable = true;
                startWhenNeeded = false;
                settings.PermitRootLogin = "yes";
              };

              users.users.root.password = "nixos";
            })
          ];
        };
      }
      // lib.attrsets.recursiveUpdate config.flakePart
        (inputs.ephemeral-machines.mkFlakePart inputs [
          ../modules/system
          ../modules/hardware/incus.nix
        ]).flakePart;
  };
}
