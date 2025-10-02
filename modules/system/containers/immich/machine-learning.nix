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
        image = "ghcr.io/immich-app/immich-machine-learning:v2.0.0@sha256:68bd95ff703a3b4c6a662b7f638bd2e01e3c7aeb2223dc0f142f02a555e24ca4";
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
