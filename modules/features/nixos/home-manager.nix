{ inputs, ... }:
{
  flake.nixosModules.features-nixos-home-manager =
    { config, lib, ... }:
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
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;

          users."${cfg.username}" = {
            imports = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.stylix.homeModules.stylix
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
