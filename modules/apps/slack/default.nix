{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.slack;
  slackPkg = pkgs.slack.overrideAttrs (oldAttrs: {
    postInstall = ({ postInstall = ""; } // oldAttrs).postInstall + ''
      wrapProgram "$out/bin/slack" \
        --set 'HOME' '${config.xdg.configHome}'
    '';
  });
in
{
  options.myHomeApps.slack = {
    enable = lib.mkEnableOption "slack";
    desktopNumber = lib.mkOption {
      type = lib.types.int;
      description = "Virtual desktop number.";
      default = 9;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        slackPkg # slack needs direct installation to register uri shortcuts for signing in, also: quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome = {
        autorun = [ (lib.getExe slackPkg) ];
        awfulRules = [
          {
            rule = {
              class = "Slack";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = " ${builtins.toString cfg.desktopNumber} ";
            };
          }
        ];
      };
      allowUnfree = [ "slack" ];
    };
  };
}
