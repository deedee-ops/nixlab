{ config, lib, ... }:
let
  cfg = config.mySystem.impermanence;
in
{
  options.mySystem.impermanence = {
    enable = lib.mkEnableOption "system impermanence";
    rootBlankSnapshotName = lib.mkOption {
      type = lib.types.str;
      default = "blank";
    };
    persistPath = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.mySystem.filesystem == "zfs";
        message = "Impermanence is supported only on ZFS";
      }
    ];

    # bind a initrd command to rollback to blank root after boot
    boot.initrd.postDeviceCommands = lib.mkAfter (
      lib.optionalString (config.mySystem.filesystem == "zfs") ''
        zfs rollback -r rpool@${cfg.rootBlankSnapshotName}
      ''
    );

    environment.persistence."${cfg.persistPath}" = {
      hideMounts = true;
      directories = [
        "/var/log" # persist logs between reboots for debugging
        "/var/lib/nixos" # nixos state
      ];
      files = [
        "/etc/machine-id"
        "/etc/adjtime" # hardware clock adjustment
      ];
    };
  };
}
