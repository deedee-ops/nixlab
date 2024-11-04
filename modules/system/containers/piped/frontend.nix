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
        image = "ghcr.io/deedee-ops/piped-frontend:latest@sha256:671f618a71cbf8ec3a352a6a7abb8a461cf86ba4ba1a54958f620e8a7a72fc46";
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
        disableReadOnly = true;
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
        icon = "https://cdn.jsdelivr.net/gh/TeamPiped/Piped/public/img/icons/logo.svg";
        description = "Private YouTube proxy";
      };
    };
  };
}
