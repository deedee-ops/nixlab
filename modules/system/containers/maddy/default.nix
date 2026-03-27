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
        image = "ghcr.io/foxcpp/maddy:0.9.2@sha256:8543fa642142a7fca04849a4ec4ef2715416944a35f45b16ec8ab9f5ec959485";
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
