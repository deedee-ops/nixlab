{
  config,
  lib,
  svc,
  dockerEnv,
  secretEnvs,
  ...
}:
let
  cfg = config.mySystemApps.immich;
  configuration = svc.templateFile {
    name = "config.json";
    src = ./config.json;

    vars = {
      ROOT_DOMAIN = config.mySystem.rootDomain;
      SMTP_FROM = config.mySystem.notificationSender;
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.immich-server = svc.mkContainer {
      cfg = {
        image = "ghcr.io/immich-app/immich-server:v1.139.4@sha256:c3c5eeafa5549e446b5fd71394399178d9c87da1dec5fd9e9a80a5a0f13e9fad";
        user = "65000:65000";
        environment = dockerEnv;
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${
              config.sops.secrets."${config.mySystemApps.redis.passFileSopsSecret}".path
            }:/secrets/REDIS_PASSWORD:ro"
            "/run/immich/config.json:/config/config.json:ro"
            "${cfg.dataPath}:/data"
          ]
          ++ lib.optionals (cfg.photosPath != null) [ "${cfg.photosPath}:/external:ro" ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
          "--device=/dev/dri"
          "--add-host=authelia.${config.mySystem.rootDomain}:${config.mySystemApps.docker.network.private.hostIP}"
        ];
      };
    };

    systemd.services.docker-immich-server = {
      preStart = lib.mkAfter ''
        mkdir -p /run/immich
        sed "s,@@OIDC_SECRET_RAW@@,$(cat ${
          config.sops.secrets."${cfg.sopsSecretPrefix}/OIDC_SECRET_RAW".path
        }),g" ${configuration} > /run/immich/config.json
        chown 65000:65000 /run/immich /run/immich/config.json
      '';
    };
  };
}
