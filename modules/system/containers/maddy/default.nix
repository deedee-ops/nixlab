{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.maddy;
  secretEnvs = [
    "EGRESS_HOST"
    "EGRESS_PASSWORD"
    "EGRESS_PORT"
    "EGRESS_USERNAME"
  ];
in
{
  options.mySystemApps.maddy = {
    enable = lib.mkEnableOption "maddy container";
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/maddy/env";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "maddy";
    };

    virtualisation.oci-containers.containers.maddy = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/maddy:0.7.1@sha256:2b6c7121e7fcb224691589600fbf56004d6b6cb6573df4dffcaf8e98e1abd786";
        environment = {
          DEBUG = "no";
          INGRESS_DOMAIN = config.mySystem.rootDomain;
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };

        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [ "${./maddy.conf}:/config/maddy.conf" ];

        extraOptions = [ "--cap-add=CAP_NET_BIND_SERVICE" ];
      };
      opts = {
        # to connect to external email provider
        allowPublic = true;
      };
    };
  };
}
