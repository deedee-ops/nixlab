{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.borgmatic;

  configs = builtins.listToAttrs (
    builtins.map (name: {
      inherit name;

      value = pkgs.writeText "${name}.yaml" (
        builtins.toJSON (
          lib.recursiveUpdate {
            source_directories = [ ];
            repositories = [ ];
            exclude_caches = true;
            exclude_if_present = [ ".nobackup" ];

            # directories
            user_runtime_directory = "/config/${name}/runtime";
            user_state_directory = "/config/${name}/state";
            temporary_directory = "/config/${name}/tmp";
            borg_base_directory = "/config/${name}/borg";

            # storage
            retries = 5;
            compression = "auto,zstd";
            ssh_command = "ssh -i /config/${name}/ssh.key -o StrictHostKeyChecking=no";
            lock_wait = 5;
            archive_name_format = "${name}-{now:%Y-%m-%d-%H%M%S}";

            # retention
            keep_daily = 7;
            keep_weekly = 4;
            keep_monthly = 6;
            keep_yearly = 3;

            # consistency
            checks = [
              {
                name = "repository";
                frequency = "2 weeks";
              }
              {
                name = "archives";
                frequency = "always";
              }
            ];
            check_last = 3;
          } (builtins.getAttr name cfg.repositories)
        )
      );
    }) (builtins.attrNames cfg.repositories)
  );
in
{
  options.mySystemApps.borgmatic = {
    enable = lib.mkEnableOption "borgmatic container";
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing borgmatic envs.";
      default = "system/apps/borgmatic/envfile";
    };
    cacheDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing borg caches.";
    };
    sourceVolumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        List of volumes to be mounted inside the container as a backup source (ro).
        The volumes will be mounted under the same path as on the host.
      '';
    };
    targetVolumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        List of volumes to be mounted inside the container as a backup destination (rw).
        The volumes will be mounted under the same path as on the host.
      '';
    };
    repositories = lib.mkOption {
      type = lib.types.attrs;
      description = ''
        Set of repository configs which will be merged to the template configuration.
        Each root key is separate borgmatic configuration file.
      '';
      example = {
        backup1 = {
          source_directories = [ "/tank/data/source1" ];
          repositories = [
            {
              path = "/mnt/dest1";
              label = "local-backup1";
            }
            {
              path = "\${BORGMATIC_BACKUP1_REPO_BORGBASE_EU}";
              label = "borgbase-backup1";
            }
          ];
          encryption_passphrase = "\${BORGMATIC_BACKUP1_ENCRYPTION_PASSPHRASE}";
          healthchecks = {
            ping_url = "\${BORGMATIC_BACKUP1_HC_PING_URL}";
          };
        };
        backup2 = {
          source_directories = [ "/tank/data/source2" ];
          repositories = [
            {
              path = "/mnt/dest2";
              label = "local-backup2";
            }
          ];
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.borgmatic = svc.mkContainer {
      cfg = {
        image = "ghcr.io/borgmatic-collective/borgmatic:2.1.2@sha256:961533d6135fd67736e9fee0f7cebc4926b57840d4a210be0a0cf2de6b004996";
        environment = {
          BACKUP_CRON = "0 2 * * *";
        };
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
        volumes =
          builtins.map (name: "${builtins.getAttr name configs}:/etc/borgmatic.d/${name}.yaml:ro") (
            builtins.attrNames configs
          )
          ++ builtins.map (vol: "${vol}:${vol}:ro") cfg.sourceVolumes
          ++ [ "${cfg.cacheDir}:/config" ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--cap-add=CAP_FSETID"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
        ]
        ++ lib.lists.flatten (
          builtins.map (vol: [
            "--mount"
            "type=bind,source=${vol},target=${vol},bind-propagation=rshared"
          ]) cfg.targetVolumes
        );
      };
      opts = {
        # pushing to remote repos
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };
  };
}
