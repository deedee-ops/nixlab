{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.echo-server;
in
{
  options.mySystemApps.echo-server = {
    enable = lib.mkEnableOption "echo-server container";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.echo-server = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/echo-server:0.9.2@sha256:437acc58aa0e4a5d2d7c3acfc6d312988f79f6838e1cf09c873d1eab4de4bc6d";
        environment = {
          ENABLE__COOKIES = "true";
          ENABLE__ENVIRONMENT = "true";
          ENABLE__FILE = "true";
          ENABLE__HEADER = "true";
          ENABLE__HOST = "true";
          ENABLE__HTTP = "true";
          ENABLE__REQUEST = "true";
          LOGS__IGNORE__PING = "false";
          PORT = "3000";
        };
      };
    };

    services = {
      nginx.virtualHosts.echo-server = svc.mkNginxVHost {
        host = "echo";
        proxyPass = "http://echo-server.docker:3000";
        useAuthelia = false;
      };
    };
  };
}
