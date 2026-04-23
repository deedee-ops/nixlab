_: {
  flake.nixosModules.features-nixos-system =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.nixos.system;
    in
    {
      options = {
        features.nixos.system = {
          extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            description = "Extra packages to be installed globally on the system.";
            default = [ ];
          };
          trustedRootCertificates = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "A list of trusted root certificates in PEM format.";
            default = [ ];
          };
        };
      };

      config = {
        environment.enableAllTerminfo = true;

        fonts.packages = [
          pkgs.corefonts
          pkgs.vista-fonts
        ];

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

        nixpkgs.config.allowUnfree = true;

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
