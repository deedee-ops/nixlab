{
  config,
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
      packages = [
        pkgs.discord # for quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome = {
        autorun = [ (lib.getExe pkgs.discord) ];
        awfulRules = [
          {
            rule = {
              class = "discord";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = " 0 ";
            };
          }
        ];
      };
      allowUnfree = [ "discord" ];
    };
  };
}
