{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.workrave;
in
{
  options.myHomeApps.workrave = {
    enable = lib.mkEnableOption "workrave";
  };

  config = lib.mkIf cfg.enable {
    myHomeApps = {
      awesome = {
        autorun = [ (lib.getExe pkgs.workrave) ];
        floatingClients.name = [
          "Micro-break"
          "Rest break"
        ];
      };
    };
  };
}
