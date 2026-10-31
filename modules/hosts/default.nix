{
  self,
  inputs,
  lib,
  config,
  ...
}:
{
  options = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            deployHostname = lib.mkOption {
              type = lib.types.str;
              description = "Address deploy-rs connects to.";
              example = "dexter.internal";
            };
            interactiveSudo = lib.mkOption {
              type = lib.types.bool;
              description = "Prompt for the sudo password when deploying.";
              default = true;
            };
          };
        }
      );
      description = ''
        NixOS hosts. Each one is built from `hosts-common` and every `hosts-<name>-*` NixOS module,
        with `<name>/secrets.sops.yaml` as the default sops file.
      '';
      default = { };
    };

    flake.deploy.nodes = lib.mkOption {
      type = lib.types.attrs;
      description = "A mapper for deploy-rs.";
      default = { };
    };
  };

  config.flake = {
    nixosConfigurations = lib.mapAttrs (
      name: _:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.disko.nixosModules.disko
          inputs.home-manager.nixosModules.home-manager
          inputs.nix-index-database.nixosModules.nix-index
          inputs.sops-nix.nixosModules.sops
          inputs.stylix.nixosModules.stylix

          self.nixosModules.hosts-common
          { sops.defaultSopsFile = ./${name}/secrets.sops.yaml; }
        ]
        ++ lib.attrValues (
          lib.filterAttrs (module: _: lib.hasPrefix "hosts-${name}-" module) self.nixosModules
        );
      }
    ) config.hosts;

    deploy.nodes = lib.mapAttrs (
      name: host:
      let
        nixosConfig = self.nixosConfigurations.${name};
      in
      {
        hostname = host.deployHostname;
        inherit (host) interactiveSudo;
        profiles.system = {
          sshUser = nixosConfig.config.features.nixos.user.name;
          remoteBuild = false;
          user = "root";
          path =
            inputs.deploy-rs.lib.${nixosConfig.config.nixpkgs.hostPlatform.system}.activate.nixos
              nixosConfig;
        };
      }
    ) config.hosts;
  };
}
