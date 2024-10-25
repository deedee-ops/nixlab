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
        image = "ghcr.io/benbusby/whoogle-search:0.9.0@sha256:e9a1616cc3234cfe25f42c10d18316d60e555c248f8d46861738e44a4f50fe3a";
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
      };
    };
  };
}
