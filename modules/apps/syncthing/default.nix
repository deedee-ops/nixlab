{
  config,
  osConfig,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.syncthing;
in
{
  options.myHomeApps.syncthing = {
    enable = lib.mkEnableOption "syncthing" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing.enable = true;

    home.persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
      lib.mkIf osConfig.mySystem.impermanence.enable
        [ "Sync" ];
  };
}
