{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.thunderbird;
in
{
  options.myHomeApps.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
  };

  config = lib.mkIf cfg.enable {
    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird-latest.overrideAttrs (attr: {
        buildCommand = attr.buildCommand + ''
          wrapProgram "$executablePath" \
            --set 'HOME' '${config.home.homeDirectory}/.config'
        '';
      });

      # workaround to disable profile management by nix
      profiles = { };
    };

    home = {
      packages = [
        config.programs.thunderbird.package # for quicklaunch entry
      ];
    };

    myHomeApps.awesome = {
      autorun = [ (lib.getExe config.programs.thunderbird.package) ];
      awfulRules = [
        {
          rule = {
            class = "thunderbird";
          };
          properties = {
            screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
            tag = if config.myHomeApps.whatsie.enable then " 5 " else " 6 ";
          };
        }
      ];
      floatingClients.role = [
        "AlarmWindow"
        "ConfigManager"
      ];
    };
  };
}
