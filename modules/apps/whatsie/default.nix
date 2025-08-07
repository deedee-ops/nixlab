{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.whatsie;
  whatsiePkg = pkgs.whatsie.overrideAttrs (oldAttrs: {
    postInstall = ({ postInstall = ""; } // oldAttrs).postInstall + ''
      wrapProgram "$out/bin/whatsie" \
        --set 'HOME' '${config.xdg.configHome}'
    '';
  });
in
{
  options.myHomeApps.whatsie = {
    enable = lib.mkEnableOption "whatsie";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        whatsiePkg # for quicklaunch entry
      ];
    };

    myHomeApps.awesome = {
      autorun = [ (lib.getExe whatsiePkg) ];
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
