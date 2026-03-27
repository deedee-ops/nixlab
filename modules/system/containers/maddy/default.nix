{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.maddy;
in
{
  options.mySystemApps.maddy = {
    enable = lib.mkEnableOption "maddy container";
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing maddy envs.";
      default = "system/apps/maddy/envfile";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.maddy = svc.mkContainer {
      cfg = {
        image = "ghcr.io/foxcpp/maddy:0.9.1@sha256:44428c5f2ad7e1407678c81d646bdb2ad68afc9d2385b07c3aa2b110a72e609d";
        environment = {
          DEBUG = "no";
          INGRESS_DOMAIN = config.mySystem.rootDomain;
        };
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
        volumes = [ "${./maddy.conf}:/data/maddy.conf" ];
        extraOptions = [ "--cap-add=CAP_NET_BIND_SERVICE" ];
      };
      opts = {
        # to connect to external email provider
        allowPublic = true;
      };
    };
  };
}
