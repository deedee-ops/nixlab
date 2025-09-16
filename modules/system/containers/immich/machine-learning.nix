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
        image = "ghcr.io/immich-app/immich-machine-learning:v1.142.0@sha256:5e9cc6b9717e34f3cdc591aa860d6d29c990405ef87ad057ef95f73096ae6f29";
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
