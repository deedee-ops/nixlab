{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.caffeine;
in
{
  options.myHomeApps.caffeine = {
    enable = lib.mkEnableOption "caffeine";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.caffeine = {
      Unit = {
        After = "graphical-session-pre.target";
        Description = "caffeine";
        PartOf = "graphical-session.target";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.getExe pkgs.caffeine-ng;
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
