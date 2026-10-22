_: {
  flake.homeModules.features-home-rclone =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.rclone;
    in
    {
      options.features.home.rclone = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };
      config = {
        sops.secrets = lib.genAttrs [ "features/home/rclone/configFile" ] (_: {
          sopsFile = cfg.sopsSecretsFile;
          path = "${config.xdg.configHome}/rclone/rclone.conf";
        });
        home.packages = [ pkgs.rclone ];
      };
    };
}
