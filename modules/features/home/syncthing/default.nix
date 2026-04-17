_: {
  flake.homeModules.features-home-syncthing =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      config = {
        home = {
          activation = {
            init-syncthing = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p "${config.xdg.stateHome}/syncthing"
              if [ ! -e "${config.xdg.stateHome}/syncthing/config.xml" ]; then
                run cp "${./config.xml}" "${config.xdg.stateHome}/syncthing/config.xml"
              fi

              mkdir -p "${config.home.homeDirectory}/Sync"
            '';
          };
        };

        services.syncthing.enable = true;
        systemd.user.services = lib.mkGuiStartupService {
          package = pkgs.syncthingtray-minimal;
          command = "${lib.getExe' pkgs.syncthingtray-minimal "syncthingtray"} --wait";
        };
      };
    };
}
