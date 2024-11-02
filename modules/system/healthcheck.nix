{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.healthcheck;
in
{
  options.mySystem.healthcheck = {
    enable = lib.mkEnableOption "system healthcheck";
    urlSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing URL to ping.";
      default = "alerts/healthcheck/url";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.urlSopsSecret}" = { };
    systemd = {
      services.healthcheck = {
        description = "Ping external healthcheck";
        path = [ pkgs.curl ];
        serviceConfig.Type = "simple";
        script = ''
          curl $(cat ${config.sops.secrets."${cfg.urlSopsSecret}".path})
        '';
      };

      timers.healthcheck = {
        description = "Update pipied feeds timer.";
        wantedBy = [ "timers.target" ];
        partOf = [ "healthcheck.service" ];
        timerConfig.OnCalendar = "*:0/10";
        timerConfig.Persistent = "true";
      };
    };
  };
}
