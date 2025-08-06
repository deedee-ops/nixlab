{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.rustdesk;
in
{
  options.myHomeApps.rustdesk = {
    enable = lib.mkEnableOption "rustdesk";
  };

  config = lib.mkIf cfg.enable {
    home = {
      persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
        lib.mkIf osConfig.mySystem.impermanence.enable [
          {
            directory = ".config/rustdesk";
            method = "symlink";
          }
        ];

      packages = [
        pkgs.rustdesk # for quicklaunch entry
      ];

    };

    myHomeApps.allowUnfree = [ "libsciter" ];
  };
}
