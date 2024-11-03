{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.backup;
in
{
  options.mySystem.backup = {
    local = {
      enable = lib.mkEnableOption "local backups";
      location = lib.mkOption {
        type = lib.types.str;
        description = "Location for local backups.";
      };
      passFileSopsSecret = lib.mkOption {
        type = lib.types.str;
        description = "Sops secret name containing local restic backups password.";
      };
    };
    remotes = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Remote repository alias for restic.";
            };
            location = lib.mkOption {
              type = lib.types.str;
              description = "Location for remote backups.";
            };
            envFileSopsSecret = lib.mkOption {
              type = lib.types.str;
              description = "Sops secret name containing remote restic repository envs.";
            };
            passFileSopsSecret = lib.mkOption {
              type = lib.types.str;
              description = "Sops secret name containing remote restic backups password.";
            };
          };
        }
      );
      default = [ ];
    };
    snapshotMountPath = lib.mkOption {
      type = lib.types.str;
      description = "Location for snapshot mount.";
      default = "/mnt/backup-snapshot";
    };
  };

  config = lib.mkIf (cfg.local.enable || (builtins.length cfg.remotes > 0)) {
    assertions = [
      {
        assertion = config.mySystem.filesystem == "zfs";
        message = "Backups are supported only on ZFS";
      }
    ];

    warnings = [
      (lib.mkIf (!cfg.local.enable) "WARNING: Local backups are disabled!")
      (lib.mkIf (builtins.length cfg.remotes == 0) "WARNING: Remote backups are disabled!")
    ];

    sops.secrets =
      {
        "${cfg.local.passFileSopsSecret}" = { };
      }
      // builtins.listToAttrs (
        builtins.map (remote: {
          name = remote.passFileSopsSecret;
          value = { };
        }) cfg.remotes
      )
      // builtins.listToAttrs (
        builtins.map (remote: {
          name = remote.envFileSopsSecret;
          value = { };
        }) cfg.remotes
      );

    # ref: https://cyounkins.medium.com/correct-backups-require-filesystem-snapshots-23062e2e7a15
    systemd = {
      timers.backup-snapshot = {
        description = "Nightly ZFS snapshot timer";
        wantedBy = [ "timers.target" ];
        partOf = [ "backup-snapshot.service" ];
        timerConfig.OnCalendar = "2:00";
        timerConfig.Persistent = "true";
      };

      services.backup-snapshot = {
        description = "Nightly ZFS snapshot for backups";
        path = [
          pkgs.zfs
          pkgs.busybox
        ];
        serviceConfig.Type = "simple";
        script = ''
          mkdir -p ${cfg.snapshotMountPath} && \
          umount ${cfg.snapshotMountPath} || true && \
          zfs destroy ${config.mySystem.impermanence.zfsPool}/persist@backup || true && \
          zfs snapshot ${config.mySystem.impermanence.zfsPool}/persist@backup && \
          mount -t zfs ${config.mySystem.impermanence.zfsPool}/persist@backup ${cfg.snapshotMountPath}
        '';
      };
    };
  };
}
