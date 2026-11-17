_: {
  flake.homeModules.features-home-thunderbird =
    {
      config,
      osConfig ? null,
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
          Preferences =
            lib.mapAttrs
              (_: value: {
                Value = value;
                Status = "locked";
              })
              {
                "media.autoplay.default" = 5; # block all, muted included
                "media.autoplay.blocking_policy" = 2; # only direct user input may start playback
                "media.autoplay.allow-extension-background-pages" = false;
                "dom.webaudio.enabled" = false;
                "dom.screenwakelock.enabled" = false;
              };
        };
      };

    in
    {
      options.features.home.thunderbird = {
        trustedRootCertificates = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "A list of trusted root certificates in PEM format.";
          default = if osConfig == null then [ ] else osConfig.security.pki.certificates;
          defaultText = lib.literalExpression "osConfig.security.pki.certificates";
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
