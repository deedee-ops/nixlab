{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.telegram;
in
{
  options.myHomeApps.telegram = {
    enable = lib.mkEnableOption "telegram";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.telegram-desktop # for quicklaunch entry
      ];
    };

    myHomeApps.awesome.autorun = [ (lib.getExe pkgs.telegram-desktop) ];
  };
}
