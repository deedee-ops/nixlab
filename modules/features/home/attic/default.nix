_: {
  flake.homeModules.features-home-attic =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.attic;
    in
    {
      options.features.home.attic = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };
      config = {
        sops.secrets = lib.genAttrs [ "features/home/attic/configFile" ] (_: {
          sopsFile = cfg.sopsSecretsFile;
          path = "${config.xdg.configHome}/attic/config.toml";
        });
        home.packages = [ pkgs.attic-client ];
      };
    };
}
