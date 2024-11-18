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
        lib.mkIf osConfig.mySystem.impermanence.enable
          [
            ".config/obsidian"
            "PKM"
          ];

      packages = [
        pkgs.obsidian # for quicklaunch entry
      ];
    };

    myHomeApps.awesome.autorun = [ (lib.getExe pkgs.obsidian) ];
  };
}
