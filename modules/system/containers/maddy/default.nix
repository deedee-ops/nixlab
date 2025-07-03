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
        image = "ghcr.io/foxcpp/maddy:0.8.1@sha256:3a315845fe7f4fd99010e7d0f6c7d09fb7bb84ced7265200e09c2a9e79c7eb04";
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
