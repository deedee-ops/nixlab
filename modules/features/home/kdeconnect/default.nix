_: {
  flake.homeModules.features-home-kdeconnect =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.kdeconnect;
    in
    {
      options.features.home.kdeconnect = {
        skipTray = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Install kdeconnect daemon only, without tray indicator.";
        };
      };

      config = {
        services.kdeconnect = {
          enable = true;
          # upstream indicator unit is bound to tray.target, which nothing provides here
          indicator = false;
        };

        # not using lib.mkGuiStartupService, as its ExecCondition matches on the package store path,
        # which is shared with already running kdeconnectd - and would block the indicator forever
        systemd.user.services = lib.optionalAttrs (!cfg.skipTray) {
          kdeconnect-indicator = {
            Unit = {
              Description = "KDE Connect tray indicator";
              After = [
                "graphical-session.target"
                "kdeconnect.service"
              ];
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              ExecStartPre = "-${pkgs.glib}/bin/gdbus wait --session --timeout 30 org.kde.StatusNotifierWatcher";
              ExecStart = lib.getExe' pkgs.kdePackages.kdeconnect-kde "kdeconnect-indicator";
              Restart = "on-failure";
              RestartSec = 5;
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        };
      };
    };
}
