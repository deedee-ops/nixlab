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
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "immich-machine-learning";
    };

    virtualisation.oci-containers.containers.immich-machine-learning = svc.mkContainer {
      cfg = {
        image = "ghcr.io/immich-app/immich-machine-learning:v1.124.2@sha256:a134652b47278edfdac3187d61558e78679be39c810536193a41e9e0d894c5f4";
        user = "65000:65000";
        dependsOn = [ "immich-server" ];
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
            "/var/cache/immich:/cache"
          ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
    };

    systemd.services.docker-immich-machine-learning = {
      preStart = lib.mkAfter ''
        mkdir -p /var/cache/immich
        chown 65000:65000 /var/cache/immich
      '';
    };
  };
}
