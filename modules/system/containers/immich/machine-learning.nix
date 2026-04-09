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
        image = "ghcr.io/immich-app/immich-machine-learning:v2.7.3@sha256:ccea091ea02086bb9a4712497a6db945a10548f7817101fa18e9b20fdb4f746f";
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
      opts = {
        # downloading models
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };
  };
}
