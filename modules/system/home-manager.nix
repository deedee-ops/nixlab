{
  inputs,
  config,
  lib,
  pkgs,
  pkgs-stable,
  pkgs-master,
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
    myGames = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Gaming configuration which will be passed down to home manager";
    };
    myRetro = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Retro games and emulators configuration which will be passed down to home manager";
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
      sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
      ];

      extraSpecialArgs = {
        inherit inputs pkgs-stable pkgs-master;

        lib = inputs.nixpkgs.lib.extend (
          _: _: inputs.home-manager.lib // (import ../../lib/home.nix { inherit lib pkgs; })
        );
      };

      users."${config.mySystem.primaryUser}" = {
        inherit (config) myGames myHomeApps myRetro;

        imports = [
          inputs.krewfile.homeManagerModules.krewfile
          inputs.sops-nix.homeManagerModules.sops
          inputs.vicinae.homeManagerModules.default

          ../apps
          ../games
          ../retro
        ]
        ++ cfg.extraImports;

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

    system.activationScripts = lib.mkIf (builtins.length config.sops.age.sshKeyPaths > 0) {
      fix-sops-for-home-manager = {
        deps = [ "users" ];
        text = builtins.concatStringsSep "\n" (
          builtins.map (
            keyfile: "chown ${config.mySystem.primaryUser} ${keyfile}"
          ) config.sops.age.sshKeyPaths
        );
      };
    };
  };
}
