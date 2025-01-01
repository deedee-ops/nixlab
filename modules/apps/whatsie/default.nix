{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.whatsie;
in
{
  options.myHomeApps.whatsie = {
    enable = lib.mkEnableOption "whatsie";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.whatsie # for quicklaunch entry
      ];
    };

    myHomeApps.awesome = {
      autorun = [ (lib.getExe pkgs.whatsie) ];
      awfulRules = [
        {
          rule = {
            class = "WhatSie";
          };
          properties = {
            screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
            tag = " 9 ";
          };
        }
      ];
    };

    xdg.configFile."org.keshavnrj.ubuntu/WhatSie.conf".source = ./whatsie.conf;
  };
}
