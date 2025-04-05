{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.obsidian;
in
{
  options.myHomeApps.obsidian = {
    enable = lib.mkEnableOption "obsidian";
  };

  config = lib.mkIf cfg.enable {
    home = {
      persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
        lib.mkIf osConfig.mySystem.impermanence.enable [
          ".config/obsidian"
        ];

      packages = [
        pkgs.obsidian # for quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome = {
        autorun = [ (lib.getExe pkgs.obsidian) ];
        awfulRules = [
          {
            rule = {
              class = "obsidian";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = if config.myHomeApps.whatsie.enable then " 6 " else " 7 ";
            };
          }
        ];
      };
      allowUnfree = [ "obsidian" ];
    };
  };
}
