{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.syncthing;
in
{
  options.myHomeApps.syncthing = {
    enable = lib.mkEnableOption "syncthing";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing.enable = true;

    home = {
      activation = {
        init-syncthing = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${config.xdg.stateHome}/syncthing"
          if [ ! -e "${config.xdg.stateHome}/syncthing/config.xml" ]; then
            run cp "${./config.xml}" "${config.xdg.stateHome}/syncthing/config.xml"
          fi
        '';
      };
      persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
        lib.mkIf osConfig.mySystem.impermanence.enable
          [ "Sync" ];
    };

    myHomeApps.awesome.autorun = [ "${lib.getExe' pkgs.syncthingtray-minimal "syncthingtray"} --wait" ];
  };
}
