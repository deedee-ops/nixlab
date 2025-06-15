{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.piped;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.piped-frontend = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/piped-frontend:latest@sha256:b26f6070f00db6e43688c1febba39fbc357093bafa505ebf691781119136101e";
        dependsOn = [ "piped-api" ];
        environment = {
          BACKEND_HOSTNAME = "piped-api.${config.mySystem.rootDomain}";
        };
        extraOptions = [
          # all of them are needed, because inside there is nginx spawning
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_SETUID"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_NET_BIND_SERVICE"
        ];
      };
      opts = {
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.piped-frontend = svc.mkNginxVHost {
        host = "piped";
        proxyPass = "http://piped-frontend.docker:80";
        useAuthelia = false;
      };
    };

    mySystemApps.homepage = {
      services.Apps.Piped = svc.mkHomepage "piped" // {
        container = "piped-api";
        description = "Private YouTube proxy";
      };
    };
  };
}
