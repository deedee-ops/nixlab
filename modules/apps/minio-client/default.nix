{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.minio-client;
in
{
  options.myHomeApps.minio-client = {
    enable = lib.mkEnableOption "minio client";
    configSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing minio configuration.";
      default = "home/apps/minio-client/config";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.configSopsSecret}" = { };

    home = {
      packages = [
        pkgs.minio-client
      ];
    };

    systemd.user.services.init-minio-client = lib.mkHomeActivationAfterSops "init-minio-client" ''
      mkdir -p ${config.xdg.configHome}/minio
      ln -sf ${
        config.sops.secrets."${cfg.configSopsSecret}".path
      } ${config.xdg.configHome}/minio/config.json
    '';
  };
}
