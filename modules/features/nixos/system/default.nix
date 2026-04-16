_: {
  flake.nixosModules.features-nixos-system =
    { config, lib, ... }:
    let
      cfg = config.features.nixos.system;
    in
    {
      options = {
        systemTheme = lib.mkOption {
          type = lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Theme name";
                example = "catppuccin";
              };
              style = lib.mkOption {
                type = lib.types.str;
                description = "Theme style";
                example = "mocha";
              };
            };
          };
        };

        features.nixos.system = {
          trustedRootCertificates = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "A list of trusted root certificates in PEM format.";
            default = [ ];
          };
        };
      };

      config = {
        environment.enableAllTerminfo = true;

        nix = {
          channel.enable = false; # don't use old nix channels

          gc = {
            automatic = true;
            dates = "daily";
            options = "--delete-older-than 30d";
          };

          settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];

            use-xdg-base-directories = true;
          };
        };

        programs.nix-index-database.comma.enable = true;

        security = {
          # more file descriptors
          pam.loginLimits = [
            {
              domain = "*";
              item = "nofile";
              type = "-";
              value = "4096";
            }
          ];
          pki.certificates = cfg.trustedRootCertificates;
          sudo = {
            execWheelOnly = true;
            extraConfig = lib.mkAfter ''
              Defaults lecture="never"
            '';
          };
        };

        system.autoUpgrade = {
          enable = true;
          flake = "github:deedee-ops/nixlab";
          runGarbageCollection = true;
        };
      };
    };
}
