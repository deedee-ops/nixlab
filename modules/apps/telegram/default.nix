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

    myHomeApps.awesome = {
      autorun = [ (lib.getExe pkgs.telegram-desktop) ];
      awfulRules = [
        {
          rule = {
            class = "TelegramDesktop";
          };
          properties = {
            screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
            tag = if config.myHomeApps.whatsie.enable then " 8 " else " 9 ";
          };
        }
      ];
    };
  };
}
