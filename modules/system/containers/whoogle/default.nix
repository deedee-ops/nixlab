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
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing redlib envs.";
      default = "system/apps/whoogle/envfile";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.whoogle = svc.mkContainer {
      cfg = {
        image = "ghcr.io/benbusby/whoogle-search:latest@sha256:e17736eabda073a1924349ba57b359cab9de54c777dc8eb12ac4c45d3421557d";
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
        };
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
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
