_: {
  flake.homeModules.features-home-syncthing =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.syncthing;
    in
    {
      options.features.home.syncthing = {
        guiAddress = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:8384";
          description = "Default address to bind syncthing to.";
        };
        skipTray = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Install syncthing daemon only, without tray.";
        };
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };
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

        services.syncthing = {
          inherit (cfg) guiAddress;
          enable = true;
        };
        systemd.user.services = lib.optionalAttrs (!cfg.skipTray) (
          lib.mkGuiStartupService {
            package = pkgs.syncthingtray-minimal;
            command = "${lib.getExe' pkgs.syncthingtray-minimal "syncthingtray"} --wait";
          }
        );
      };
    };
}
