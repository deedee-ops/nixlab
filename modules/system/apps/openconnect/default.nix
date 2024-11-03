{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.openconnect;
in
{
  options.mySystemApps.openconnect = {
    enable = lib.mkEnableOption "openconnect app";
    keepAliveHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "If set - Host to be periodically visited via curl, to keep VPN connection alive.";
      default = null;
      example = "192.168.1.1:3000";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "openconnect/config" = {
          restartUnits = [ "openconnect.service" ];
        };
        "openconnect/password" = {
          restartUnits = [ "openconnect.service" ];
        };
      };
    };

    systemd = {
      services.openconnect = {
        description = "OpenConnect Interface";
        requires = [ "network-online.target" ];
        after = [
          "network.target"
          "network-online.target"
        ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.openconnect} --config=${
            config.sops.secrets."openconnect/config".path
          }";
          StandardInput = "file:${config.sops.secrets."openconnect/password".path}";
          ProtectHome = true;
        };
      };

      # poor mans keepalive
      services.openconnect-keepalive = lib.mkIf cfg.keepAliveHost {
        script = ''
          ${lib.getExe pkgs.curl} -s http://${cfg.keepAliveHost}
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
      timers.openconnect-keepalive = lib.mkIf cfg.keepAliveHost {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/5";
          Persistent = true;
          Unit = "openconnect-keepalive.service";
        };
      };
    };
  };
}
