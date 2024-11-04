{ inputs, nixConfig, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  mkNixosConfig =
    {
      system,
      baseModules ? [
        ../modules/system

        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        inputs.impermanence.nixosModules.impermanence
        inputs.lix-module.nixosModules.default
        inputs.nix-index-database.nixosModules.nix-index
        inputs.sops-nix.nixosModules.sops
        inputs.stylix.nixosModules.stylix
      ],
      hardwareModules ? [ ],
      profileModules ? [ ],
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = baseModules ++ hardwareModules ++ profileModules;
      specialArgs = {
        inherit inputs nixConfig;
      };
    };

  mkDeployConfig =
    {
      system,
      target,
      nixosConfig,
      sshUser ? "root",
    }:
    {
      hostname = target;
      interactiveSudo = true;
      profiles.system = {
        inherit sshUser;

        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos nixosConfig;
      };
    };
}
