{ config, lib, ... }:
let
  cfg = config.mySystem.impermanence;
in
{
  options.mySystem.impermanence = {
    enable = lib.mkEnableOption "system impermanence";
    machineId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = ''
        Impermanence bind mounting breaks machine-id from time to time. Less secure, but more stable way
        is just to provide it directly, and call it a day.
        When left null, it will regenerate it on every reboot (as it will be lost) - which is fine on VMs,
        but not fine on metal.
      '';
      default = null;
    };
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
      {
        assertion =
          (cfg.machineId != null && !config.virtualisation.incus.agent.enable)
          || (cfg.machineId == null && config.virtualisation.incus.agent.enable);
        message = "machineId must be set on metal, but should be left null on VMs";
      }
    ];

    boot = {
      # bind a initrd command to rollback to blank root after boot
      initrd.postResumeCommands = lib.mkAfter (
        lib.optionalString (config.mySystem.filesystem == "zfs") ''
          zfs rollback -r rpool@${cfg.rootBlankSnapshotName}
        ''
      );
    };

    environment = {
      etc = lib.mkIf (cfg.machineId != null) { machine-id.text = cfg.machineId; };

      persistence."${cfg.persistPath}" = {
        hideMounts = true;
        directories = [
          "/var/log" # persist logs between reboots for debugging
          "/var/lib/nixos" # nixos state
        ];
        files = [
          "/etc/adjtime" # hardware clock adjustment
        ];
      };
    };

    fileSystems."${cfg.persistPath}" = {
      device = "${cfg.zfsPool}/persist";
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
