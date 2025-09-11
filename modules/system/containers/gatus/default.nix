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
    vhostsMonitoring = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "vhosts monitoring" // {
            default = true;
          };
          conditionsOverride = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
            description = "Custom set of conditions for given vhosts.";
            default = { };
            example = {
              "s3" = [ "[STATUS] == 403" ];
            };
          };
        };
      };
      default = {
        enable = true;
        conditionsOverride = { };
      };
    };

    endpoints = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "List of gatus endpoints";
      default = [ ];
      example = [
        {
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
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.gatus = svc.mkContainer {
      cfg =
        let
          vhostNames = builtins.filter (
            name:
            (builtins.match "^[a-z0-9.-]+$" (
              builtins.toString (builtins.getAttr name config.services.nginx.virtualHosts).serverName
            )) != null
          ) (builtins.attrNames config.services.nginx.virtualHosts);
          endpoints =
            cfg.endpoints
            ++ (lib.optionals cfg.vhostsMonitoring.enable (
              builtins.map (
                name:
                let
                  value = builtins.getAttr name config.services.nginx.virtualHosts;
                in
                {
                  inherit name;

                  url = (if value.addSSL then "https" else "http") + "://${value.serverName}/";
                  interval = "30s";
                  conditions =
                    if (builtins.hasAttr name cfg.vhostsMonitoring.conditionsOverride) then
                      (builtins.getAttr name cfg.vhostsMonitoring.conditionsOverride)
                    else
                      [ "[STATUS] < 300" ];
                  alerts = [
                    {
                      type = "email";
                      enabled = true;
                    }
                  ];
                }
              ) vhostNames
            ));

          configFile = pkgs.writeText "config" (
            builtins.toJSON {
              inherit endpoints;

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
          image = "ghcr.io/twin/gatus:v5.23.2@sha256:041514059279f102d8e549a7c7c9f813ae9a0bf505c6d7c37aea9201af0bec3a";
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
