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
        image = "ghcr.io/immich-app/immich-machine-learning:v2.6.0@sha256:ea9d2fc9ede44071957c7f1191fc86a842362cf3e8e6667b5c8a449442758d56";
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
