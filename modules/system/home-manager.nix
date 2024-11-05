{
  inputs,
  config,
  lib,
  nixConfig,
  ...
}:
let
  cfg = config.mySystem.home-manager;
in
{
  options = {
    myHomeApps = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Apps configuration which will be passed down to home manager";
    };

    homeApps = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra home apps options used internally by system modules";
      internal = true;
    };

    mySystem.home-manager = {
      extraImports = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = "List of extra nix files to be imported as home manager modules";
      };
    };
  };

  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs;

        lib = inputs.nixpkgs.lib.extend (
          _: _: inputs.home-manager.lib // (import ../../lib { inherit inputs nixConfig; })
        );
      };

      users."${config.mySystem.primaryUser}" = {
        myHomeApps = lib.recursiveUpdate config.myHomeApps (
          lib.recursiveUpdate config.homeApps (
            # absolutely disgusting hack
            lib.optionalAttrs
              ((builtins.hasAttr "awesome" config.myHomeApps) && (builtins.hasAttr "awesome" config.homeApps))
              {
                awesome = {
                  autorun = config.myHomeApps.awesome.autorun ++ config.homeApps.awesome.autorun;
                };
              }
          )
        );

        imports = [
          inputs.krewfile.homeManagerModules.krewfile
          inputs.impermanence.nixosModules.home-manager.impermanence
          inputs.sops-nix.homeManagerModules.sops

          ../apps
        ] ++ cfg.extraImports;

        nix.settings = nixConfig;

        sops = {
          inherit (config.sops) defaultSopsFile age;
        };

        home = {
          username = "${config.mySystem.primaryUser}";
          homeDirectory = "/home/${config.mySystem.primaryUser}";
          stateVersion = "24.11";
        };
      };
    };
  };
}
