_: {
  flake.homeModules.features-home-thunderbird =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.thunderbird;
      thunderbirdPkg = pkgs.thunderbird.override {
        extraPolicies = {
          Certificates = {
            Install = [
              "${pkgs.writeText "custom-ca.crt" (builtins.concatStringsSep "\n" cfg.trustedRootCertificates)}"
            ];
          };
        };
      };

    in
    {
      options.features.home.thunderbird = {
        trustedRootCertificates = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "A list of trusted root certificates in PEM format.";
          default = [ ];
        };
      };

      config = {
        programs.thunderbird = {
          enable = true;
          package = thunderbirdPkg;

          # workaround to disable profile management by nix
          profiles = { };
        };

        home.packages = [ thunderbirdPkg ];

        systemd.user.services = lib.mkGuiStartupService { package = thunderbirdPkg; };
      };
    };
}
