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
          image = "ghcr.io/twin/gatus:v5.19.0@sha256:12362572b78c1bb6f234248de33392a393f7e604d94779e3086ec2dbba1bedf3";
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
