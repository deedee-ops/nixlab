{ nixConfig, ... }: {
  flake.homeModules.features-home-nix =
    { config, lib, ... }:
    let
      cfg = config.features.home.nix;
    in
    {
      options.features.home.nix = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };
      config = {
        sops.secrets = lib.genAttrs [ "features/home/shell/nix/accessTokens" ] (_: {
          sopsFile = cfg.sopsSecretsFile;
        });
        nix = {
          settings = nixConfig;
          extraOptions = ''
            !include ${config.sops.secrets."features/home/shell/nix/accessTokens".path}
          '';
        };
      };
    };
}
