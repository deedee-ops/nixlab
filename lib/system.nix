{
  inputs,
  nixConfig,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
in
{

  mkNixosConfig =
    {
      system,
      osConfig,
      baseModules ? [
        ../modules/infra
        ../modules/system

        inputs.disko.nixosModules.disko
        inputs.headplane.nixosModules.headplane
        inputs.home-manager.nixosModules.home-manager
        inputs.impermanence.nixosModules.impermanence
        inputs.nix-index-database.nixosModules.nix-index
        inputs.sops-nix.nixosModules.sops
        inputs.stylix.nixosModules.stylix
        inputs.ucodenix.nixosModules.default
      ],
      hardwareModules ? [ ],
      profileModules ? [ ],
    }:
    inputs.nixpkgs.lib.nixosSystem (
      let
        pkgsOpts = {
          inherit system;
          overlays = builtins.attrValues (import ../overlays { inherit inputs; });
          config = {
            allowUnfreePredicate =
              pkg:
              builtins.elem (lib.getName pkg) (
                osConfig.mySystem.allowUnfree
                ++ osConfig.home-manager.users."${osConfig.mySystem.primaryUser}".myHomeApps.allowUnfree
              );
            permittedInsecurePackages = osConfig.mySystem.allowInsecure;

            cudaSupport = osConfig.myHardware.nvidia.enable && osConfig.myHardware.nvidia.forceCompileCUDA;
            rocmSupport = osConfig.myHardware.radeon.enable && osConfig.myHardware.radeon.forceCompileROCM;
          };
        };

        pkgs = import inputs.nixpkgs pkgsOpts;
        pkgs-stable = import inputs.nixpkgs-stable pkgsOpts;
        pkgs-master = import inputs.nixpkgs-master pkgsOpts;
      in
      {
        inherit system pkgs;
        modules = baseModules ++ hardwareModules ++ profileModules;
        specialArgs = {
          inherit
            inputs
            nixConfig
            pkgs-stable
            pkgs-master
            ;
        };
      }
    );

  mkDeployConfig =
    {
      system,
      target,
      nixosConfig,
      sshUser ? "root",
      remoteBuild ? false,
    }:
    {
      hostname = target;
      interactiveSudo = true;
      profiles.system = {
        inherit sshUser remoteBuild;

        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos nixosConfig;
      };
    };
}
