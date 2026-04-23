_: {
  flake.homeModules.features-home-gnupg =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.gnupg;
    in
    {
      options.features.home.gnupg = {
        pinentryPackage = lib.mkOption {
          type = lib.types.package;
          default = pkgs.pinentry-curses;
          description = "Pinentry package.";
        };
        publicKeys = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          description = "List of paths to public keys";
          default = [ ./ajgon.gpg ];
        };
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };
      config = {
        sops.secrets = lib.genAttrs [ "features/home/gnupg/keyId" "features/home/gnupg/keyData" ] (_: {
          sopsFile = cfg.sopsSecretsFile;
        });

        home.shellAliases.gpgkill = "${lib.getExe' pkgs.gnupg "gpgconf"} --kill gpg-agent";

        programs.gpg = {
          enable = true;

          homedir = "${config.xdg.dataHome}/gnupg";
          mutableKeys = false;
          mutableTrust = false;

          publicKeys = builtins.map (src: {
            source = src;
            trust = "ultimate";
          }) cfg.publicKeys;
        };

        services.gpg-agent = {
          enable = true;
          defaultCacheTtl = 28800;
          pinentry.package = cfg.pinentryPackage;
        };

        systemd.user.services.init-gnupg = lib.mkHomeActivationAfterSops {
          name = "init-gnupg";
          script = ''
            ${lib.getExe pkgs.gnupg} --list-secret-keys "$(cat ${
              config.sops.secrets."features/home/gnupg/keyId".path
            })" > /dev/null || ${lib.getExe pkgs.gnupg} --batch --import ${
              config.sops.secrets."features/home/gnupg/keyData".path
            }
          '';
          envs = [ "GNUPGHOME=${config.home.sessionVariables.GNUPGHOME}" ];
        };
      };
    };
}
