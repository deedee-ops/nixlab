_: {
  flake.homeModules.features-home-minio-cli =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.minio-cli;
    in
    {
      options.features.home.minio-cli = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };
      config = {
        sops.secrets = lib.genAttrs [ "features/home/minio-cli/configFile" ] (_: {
          sopsFile = cfg.sopsSecretsFile;
          path = "${config.xdg.configHome}/minio/config.json";
        });
        home.packages = [ pkgs.minio-client ];
      };
    };
}
