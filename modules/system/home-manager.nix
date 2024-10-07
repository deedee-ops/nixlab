{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.mySystem.home-manager;
in
{
  options.myApps = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Apps configuration which will be passed down to home manager";
  };

  options.mySystem.home-manager = {
    extraImports = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of extra nix files to be imported as home manager modules";
    };
  };

  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs;

        lib = inputs.nixpkgs.lib.extend (
          _: _: inputs.home-manager.lib // (import ../../lib { inherit inputs; })
        );
      };

      users."${config.mySystem.primaryUser}" = {
        inherit (config) myApps;

        imports = [
          inputs.krewfile.homeManagerModules.krewfile

          ../apps/default.nix
        ] ++ cfg.extraImports;

        home = {
          username = "${config.mySystem.primaryUser}";
          homeDirectory = "/home/${config.mySystem.primaryUser}";
          stateVersion = "24.11";
        };
      };
    };
  };
}
