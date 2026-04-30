_: {
  flake.nixosModules.features-nixos-user =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.nixos.user;
    in
    {
      options.features.nixos.user = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Main non-privileged username";
        };
        extraDirectories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Extra directories outside home owner by the user";
          default = [ ];
          example = [ "/mnt/usb" ];
        };
      };
      config = {
        sops.secrets = {
          "features/nixos/user/hashedPassword".neededForUsers = true;
          "features/nixos/user/homeAgeKey" = {
            inherit (config.users.users."${cfg.name}") group;
            owner = config.users.users."${cfg.name}".name;
            mode = "0440";
            path = "${config.users.users."${cfg.name}".home}/.config/sops/age/keys.txt";
          };
        };

        users.users."${cfg.name}" = {
          isNormalUser = true;
          description = "${cfg.name}";
          extraGroups = [
            "input"
            "networkmanager"
            "render"
            "video"
            "wheel"
          ];
          shell = pkgs.zsh;
          hashedPasswordFile = config.sops.secrets."features/nixos/user/hashedPassword".path;
        };

        nix.settings = {
          allowed-users = [ cfg.name ];
          trusted-users = [ cfg.name ];
        };

        programs.zsh = {
          enable = true;
          enableGlobalCompInit = false;
        };

        system.activationScripts = {
          create-extra-dirs-and-fix-home-perms = {
            deps = [
              "users"
              "setupSecrets"
            ];
            text = ''
              chown -R ${cfg.name}:users "${config.users.users."${cfg.name}".home}"
            ''
            + lib.concatStringsSep "\n" (
              builtins.map (extraDir: ''
                mkdir -p ${extraDir} || true
                chown ${cfg.name}:users "${extraDir}"
              '') cfg.extraDirectories
            );
          };
        };
      };
    };
}
