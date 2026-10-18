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
        rescanIntervalS = lib.mkOption {
          type = lib.types.int;
          default = 3600;
          description = "Fallback full-rescan interval in seconds for all folders managed by this host.";
        };
        reconnectionIntervalS = lib.mkOption {
          type = lib.types.int;
          default = 60;
          description = "Interval in seconds between reconnection attempts to disconnected devices.";
        };
        ignores = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          default = { };
          example = {
            workspace = [ "(?d).DS_Store" ];
          };
          description = ''
            Per-folder .stignore patterns, keyed by folder path relative to home.
            Syncthing never syncs .stignore, so every device needs its own copy.
            Written on activation as a regular file, overwriting edits made in the GUI.
          '';
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
            init-syncthing = lib.hm.dag.entryAfter [ "writeBoundary" ] (
              ''
                mkdir -p "${config.xdg.stateHome}/syncthing"
                if [ ! -e "${config.xdg.stateHome}/syncthing/config.xml" ]; then
                  run cp "${./config.xml}" "${config.xdg.stateHome}/syncthing/config.xml"
                fi

                run ${pkgs.gnused}/bin/sed -i \
                  's/rescanIntervalS="[0-9]*"/rescanIntervalS="${toString cfg.rescanIntervalS}"/g' \
                  "${config.xdg.stateHome}/syncthing/config.xml"

                run ${pkgs.gnused}/bin/sed -i \
                  's|<reconnectionIntervalS>[0-9]*</reconnectionIntervalS>|<reconnectionIntervalS>${toString cfg.reconnectionIntervalS}</reconnectionIntervalS>|g' \
                  "${config.xdg.stateHome}/syncthing/config.xml"

                mkdir -p "${config.home.homeDirectory}/Sync"
              ''
              + lib.concatStrings (
                lib.mapAttrsToList (folder: patterns: ''
                  run install -Dm644 ${pkgs.writeText "stignore" (lib.concatLines patterns)} "${config.home.homeDirectory}/${folder}/.stignore"
                '') cfg.ignores
              )
            );
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
