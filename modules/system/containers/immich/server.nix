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
        image = "ghcr.io/immich-app/immich-server:v1.125.6@sha256:07e45e10be9539f04dd3a819286b5b308b08142eeff7bc58a89bf21d97237d55";
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
            "${cfg.photosPath}:/external:ro"
          ];
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
