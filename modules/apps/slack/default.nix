{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.slack;
  slackPkg = pkgs.slack;
in
{
  options.myHomeApps.slack = {
    enable = lib.mkEnableOption "slack";
  };

  config = lib.mkIf cfg.enable {
    home = {
      persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
        lib.mkIf osConfig.mySystem.impermanence.enable [ ".config/Slack" ];

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
              tag = " 4 ";
            };
          }
        ];
      };
      allowUnfree = [ "slack" ];
    };
  };
}
