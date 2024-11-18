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

    myHomeApps.awesome.autorun = [ (lib.getExe pkgs.whatsie) ];

    xdg.configFile."org.keshavnrj.ubuntu/WhatSie.conf".source = ./whatsie.conf;
  };
}
