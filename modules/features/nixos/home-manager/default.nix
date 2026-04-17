{ inputs, ... }:
{
  flake.nixosModules.features-nixos-home-manager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.nixos.home-manager;
    in
    {
      options.features.nixos.home-manager = {
        username = lib.mkOption {
          type = lib.types.str;
          description = "User to install home-manager for";
        };
        modules = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          default = [ ];
        };
      };

      config = {
        environment = {
          systemPackages = [
            # https://github.com/nix-community/home-manager/issues/3113
            pkgs.dconf
          ];
        };
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;

          extraSpecialArgs = {
            lib = inputs.nixpkgs.lib.extend (
              _: _: inputs.home-manager.lib // (import ../../../../lib/home.nix { inherit pkgs; })
            );
          };

          users."${cfg.username}" = {
            imports = [
              inputs.krewfile.homeManagerModules.krewfile
              inputs.sops-nix.homeManagerModules.sops
              inputs.vicinae.homeManagerModules.default
            ]
            ++ cfg.modules;

            sops = {
              inherit (config.sops) defaultSopsFile age;
            };

            home = {
              inherit (cfg) username;
              homeDirectory = "/home/${cfg.username}";
              stateVersion = "25.11";
            };
          };
        };
      };
    };
}
