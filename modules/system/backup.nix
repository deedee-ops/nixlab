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
    };
    remote = {
      enable = lib.mkEnableOption "local backups";
      repositoryFileSopsSecret = lib.mkOption {
        type = lib.types.str;
        description = "Sops secret name containing remote restic repository url.";
      };
    };
    snapshotMountPath = lib.mkOption {
      type = lib.types.str;
      description = "Location for snapshot mount.";
      default = "/mnt/backup-snapshot";
    };
    passFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing restic backups password.";
    };

  };

  config = lib.mkIf (cfg.local.enable || cfg.remote.enable) {
    assertions = [
      {
        assertion = config.mySystem.filesystem == "zfs";
        message = "Backups are supported only on ZFS";
      }
    ];

    warnings = [
      (lib.mkIf (!cfg.local.enable) "WARNING: Local backups are disabled!")
      (lib.mkIf (!cfg.remote.enable) "WARNING: Remote backups are disabled!")
    ];

    sops.secrets = {
      "${cfg.passFileSopsSecret}" = { };
      "${cfg.remote.repositoryFileSopsSecret}" = { };
    };

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
          zfs destroy rpool/persist@backup || true && \
          zfs snapshot rpool/persist@backup && \
          mount -t zfs rpool/persist@backup ${cfg.snapshotMountPath}
        '';
      };
    };
  };
}
