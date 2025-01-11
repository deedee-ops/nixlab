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
    zfsRootBlankSnapshotName = lib.mkOption {
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
        assertion = config.mySystem.filesystem == "zfs" || config.mySystem.filesystem == "btrfs";
        message = "Impermanence is supported only on ZFS or BTRFS";
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
      initrd = {
        postDeviceCommands = lib.mkAfter (
          lib.optionalString (config.mySystem.filesystem == "btrfs") ''
            mkdir /btrfs_tmp
            mount ${builtins.head config.mySystem.disks.systemDiskDevs} /btrfs_tmp
            if [[ -e /btrfs_tmp/root ]]; then
                mkdir -p /btrfs_tmp/old_roots
                timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
                mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
            fi

            delete_subvolume_recursively() {
                IFS=$'\n'
                for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                    delete_subvolume_recursively "/btrfs_tmp/$i"
                done
                btrfs subvolume delete "$1"
            }

            for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
                delete_subvolume_recursively "$i"
            done

            btrfs subvolume create /btrfs_tmp/root
            umount /btrfs_tmp
          ''
        );
        postResumeCommands = lib.mkAfter (
          lib.optionalString (config.mySystem.filesystem == "zfs") ''
            zfs rollback -r rpool@${cfg.zfsRootBlankSnapshotName}
          ''
        );
      };
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

    fileSystems."${cfg.persistPath}" =
      if config.mySystem.filesystem == "zfs" then
        {
          device = "${cfg.zfsPool}/persist";
          fsType = "zfs";
          neededForBoot = true;
        }
      else
        {
          device = builtins.head config.mySystem.disks.systemDiskDevs;
          neededForBoot = true;
          fsType = "btrfs";
          options = [ "subvol=${cfg.persistPath}" ];
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
