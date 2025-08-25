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
        image = "ghcr.io/deedee-ops/piped-frontend:latest@sha256:cff08c16fec2da49bc049272e3744f35ca5102d99e3ba3c93d9fdce3d75840b0";
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
