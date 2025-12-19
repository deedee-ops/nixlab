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
        image = "ghcr.io/immich-app/immich-server:v2.4.1@sha256:2c496e3b9d476ea723e6f0df05d1f690fed2d79b61f4ed75597679892d86311a";
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
