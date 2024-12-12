{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.discord;
in
{
  options.myHomeApps.discord = {
    enable = lib.mkEnableOption "discord";
  };

  config = lib.mkIf cfg.enable {
    home = {
      persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
        lib.mkIf osConfig.mySystem.impermanence.enable [ ".config/discord" ];

      packages = [
        pkgs.discord # for quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome.autorun = [ (lib.getExe pkgs.discord) ];
      allowUnfree = [ "discord" ];
    };
  };
}
