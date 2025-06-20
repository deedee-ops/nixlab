{
  config,
  lib,
  svc,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.gatus;
in
{
  options.mySystemApps.gatus = {
    enable = lib.mkEnableOption "gatus container";
    alertEmails = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of emails receiving gatus alerts";
      default = [ ];
    };
    endpoints = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "List of gatus endpoints";
      default = [ ];
      example = {
        name = "redis";
        url = "tcp://redis:6397";
        interval = "30s";
        conditions = [ "[CONNECTED] == true" ];
        alerts = [
          {
            type = "email";
            enabled = true;
          }
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.gatus = svc.mkContainer {
      cfg =
        let
          configFile = pkgs.writeText "config" (
            builtins.toJSON {
              inherit (cfg) endpoints;

              alerting = {
                email = {
                  from = config.mySystem.notificationSender;
                  host = "maddy";
                  port = 25;
                  to = builtins.concatStringsSep "," cfg.alertEmails;
                };
              };
            }
          );
        in
        {
          image = "ghcr.io/twin/gatus:v5.18.1@sha256:97525568fdef34539b1b4d015aef2d1cf6f58f1bc087443387b349940544394d";
          user = "65000:65000";
          volumes = [ "${configFile}:/config/config.yaml" ];
        };
      opts = {
        # allow monitoring external sources
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.gatus = svc.mkNginxVHost {
        host = "gatus";
        proxyPass = "http://gatus.docker:8080";
      };
    };

    mySystemApps.homepage = {
      services.Apps.Gatus = svc.mkHomepage "gatus" // {
        description = "Services monitoring";
        widget = {
          type = "gatus";
          url = "http://gatus:8080";
          fields = [
            "up"
            "down"
            "uptime"
          ];
        };
      };
    };
  };
}
