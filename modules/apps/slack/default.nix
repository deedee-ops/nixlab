{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.slack;
in
{
  options.myHomeApps.slack = {
    enable = lib.mkEnableOption "slack";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.slack # slack needs direct installation to register uri shortcuts for signing in, also: quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome = {
        autorun = [ (lib.getExe pkgs.slack) ];
        awfulRules = [
          {
            rule = {
              class = "Slack";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = " 4 ";
            };
          }
        ];
      };
      allowUnfree = [ "slack" ];
    };
  };
}
