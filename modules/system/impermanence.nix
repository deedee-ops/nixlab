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
    zfsPool = lib.mkOption {
      type = lib.types.enum [
        "rpool"
        "tank"
      ];
      default = "rpool";
      description = "Pool where persist volume dataset should be configured.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.mySystem.filesystem == "zfs";
        message = "Impermanence is supported only on ZFS";
      }
    ];

    boot = {
      # bind a initrd command to rollback to blank root after boot
      initrd.postResumeCommands = lib.mkAfter (
        lib.optionalString (config.mySystem.filesystem == "zfs") ''
          zfs rollback -r rpool@${cfg.rootBlankSnapshotName}
        ''
      );
      # zfs.forceImportAll = cfg.zfsPool == "tank";
    };

    environment.persistence."${cfg.persistPath}" = {
      hideMounts = true;
      directories = [
        "/var/log" # persist logs between reboots for debugging
        "/var/lib/nixos" # nixos state
      ];
      files = [
        "/etc/adjtime" # hardware clock adjustment
      ] ++ lib.optionals (!config.virtualisation.incus.agent.enable) [ "/etc/machine-id" ]; # on VMs machine-id is constant, regenerated for vm uuid each time, and it breaks impermanence
    };

    fileSystems."${cfg.persistPath}" = {
      device = "${cfg.zfsPool}/persist";
      # device = "rpool/persist";
      fsType = "zfs";
      neededForBoot = true;
    };

    programs.fuse.userAllowOther = true;

    system.activationScripts = {
      imermanence-home =
        let
          homedir = "${cfg.persistPath}${
            config.home-manager.users."${config.mySystem.primaryUser}".home.homeDirectory
          }";
        in
        {
          deps = [ "users" ];
          text = ''
            mkdir -p "${homedir}" || true
            chown ${config.mySystem.primaryUser}:users "${homedir}"
            chmod 700 "${homedir}"
          '';
        };
    };
  };
}
