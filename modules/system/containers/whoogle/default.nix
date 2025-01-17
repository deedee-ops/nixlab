{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.whoogle;
in
{
  options.mySystemApps.whoogle = {
    enable = lib.mkEnableOption "whoogle container";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.whoogle = svc.mkContainer {
      cfg = {
        image = "ghcr.io/benbusby/whoogle-search:0.9.1@sha256:f3649f5652495deed4ea228a13bdb54dce480af39ba1e48f11fbab541b68e858";
        # disable tor
        cmd = [
          "/bin/sh"
          "-c"
          "./run"
        ];
        environment = {
          EXPOSE_PORT = "5000";
          WHOOGLE_CONFIG_DISABLE = "1";
          WHOOGLE_CONFIG_GET_ONLY = "1";
          WHOOGLE_CONFIG_NEW_TAB = "1";
          WHOOGLE_CONFIG_THEME = "dark";
          WHOOGLE_CONFIG_URL = "https://whoogle.${config.mySystem.rootDomain}";
          WHOOGLE_TOR_SERVICE = "0";
          WHOOGLE_CONFIG_TOR = "0";
          WHOOGLE_SHOW_FAVICONS = "0";

          # https://github.com/benbusby/whoogle-search/issues/1211
          WHOOGLE_USE_CLIENT_USER_AGENT = "0";
          WHOOGLE_USER_AGENT = "Mozilla/3.0 (compatible; MSIE 3.0; Windows NT 5.0)";
        };
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/whoogle/app/static/build,tmpfs-mode=1777"
        ];
      };
      opts = {
        # proxying to google
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.whoogle = svc.mkNginxVHost {
        host = "whoogle";
        proxyPass = "http://whoogle.docker:5000";
        useAuthelia = false;
        customCSP = "disable"; # images results
      };
    };

    mySystemApps.homepage = {
      services.Apps.Whoogle = svc.mkHomepage "whoogle" // {
        icon = "whoogle.png";
        description = "Google Proxy and Anonymizer";
      };
    };
  };
}
