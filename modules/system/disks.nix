{ config, lib, ... }:
let
  cfg = config.mySystem.disks;
in
{
  options.mySystem.disks = with lib; {
    enable = mkEnableOption "disks setup and partitioning";
    hostId = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The 32-bit host ID of the machine, formatted as 8 hexadecimal characters. To ensure when using ZFS that a pool isn’t imported accidentally on a wrong machine.";
    };
    swapSize = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Swap size with unit.";
      example = "4G";
    };
    systemDiskDevs = mkOption {
      type = types.listOf types.str;
      description = "List of device paths for system pool. Some space on first device will be reserved for EFI and SWAP. Remaining space and other disks will be merged in one ZFS pool.";
      example = [
        "/dev/sda"
        "/dev/sdb"
      ];
    };
    systemDatasets = mkOption {
      type = types.nullOr types.attrs;
      description = "List of preinitialized datasets on system pool.";
      default =
        if config.mySystem.filesystem == "zfs" then
          {
            nix = {
              mountpoint = "/nix";
              type = "zfs_fs";
            };
          }
        else if config.mySystem.filesystem == "btrfs" then
          {
            "/nix" = {
              mountpoint = "/nix";
              mountOptions = [
                "noatime"
                "compress=zstd"
              ];
            };
          }
        else
          { };
      example = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
    };
    cacheDiskDev = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Device path for ZFS cache disk. Applicable only if tankDiskDevs is set.";
      example = "/dev/sdc";
    };
    tankDiskDevs = mkOption {
      type = types.listOf types.str;
      description = "List of extra device paths, which will be used as tank. Applies only for NAS configurations.";
      default = [ ];
      example = [
        "/dev/sdd"
        "/dev/sde"
        "/dev/sdf"
        "/dev/sdg"
        "/dev/sdh"
        "/dev/sdi"
      ];
    };
    tankDatasets = mkOption {
      type = types.nullOr types.attrs;
      description = "List of preinitialized datasets on tank pool.";
      default = { };
      example = {
        private = {
          type = "zfs_fs";
        };
        media = {
          type = "zfs_fs";
          mountpoint = "/media";
        };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.mySystem.filesystem == "zfs" || builtins.length cfg.systemDiskDevs == 1;
        message = "Only one `systemDiskDevs` can be set for global filesystem different than zfs";
      }
      {
        assertion = config.mySystem.filesystem != "zfs" || builtins.length cfg.systemDiskDevs >= 1;
        message = "At least one `systemDiskDevs` must be set for zfs global filesystem";
      }
      {
        assertion = config.mySystem.filesystem != "zfs" || cfg.hostId != null;
        message = "`hostId` is required for zfs";
      }
      {
        assertion = config.mySystem.filesystem == "zfs" || cfg.cacheDiskDev == null;
        message = "`cacheDiskDev` cannot be set for global filesystem different than zfs";
      }
      {
        assertion = config.mySystem.filesystem == "zfs" || cfg.tankDiskDevs == [ ];
        message = "`tankDiskDevs` cannot be set for global filesystem different than zfs";
      }
    ];

    networking.hostId = cfg.hostId;

    disko.devices =
      {
        disk =
          {
            system = {
              device = builtins.head cfg.systemDiskDevs;

              type = "disk";
              content = {
                type = "gpt";
                partitions =
                  {
                    boot = {
                      name = "boot";
                      size = "1M";
                      type = "EF02";
                    };
                    esp = {
                      name = "ESP";
                      size = "512M";
                      type = "EF00";
                      content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                      };
                    };
                    swap = lib.mkIf (cfg.swapSize != null) {
                      size = "100%";
                      content = {
                        type = "swap"; # this also takes care of fstab entry so you don't need to configure `swapDevices` separately
                        discardPolicy = "both";
                        resumeDevice = true;
                      };
                    };
                  }
                  // lib.optionalAttrs (config.mySystem.filesystem == "ext4") {
                    root = {
                      content = {
                        type = "lvm_pv";
                        vg = "rpool";
                      };
                    } // lib.optionalAttrs (cfg.swapSize != null) { end = "-${cfg.swapSize}"; };
                  }
                  // lib.optionalAttrs (config.mySystem.filesystem == "btrfs") {
                    root = {
                      content = {
                        type = "btrfs";
                        extraArgs = [ "-f " ];
                        subvolumes =
                          {
                            "/root" = {
                              mountOptions = [
                                "noatime"
                                "compress=zstd"
                              ];
                              mountpoint = "/";
                            };

                          }
                          // cfg.systemDatasets
                          // lib.optionalAttrs config.mySystem.impermanence.enable {
                            "${config.mySystem.impermanence.persistPath}" = {
                              mountOptions = [
                                "noatime"
                                "compress=zstd"
                              ];
                              mountpoint = "${config.mySystem.impermanence.persistPath}";
                            };
                          };
                      };
                    } // lib.optionalAttrs (cfg.swapSize != null) { end = "-${cfg.swapSize}"; };
                  }
                  // lib.optionalAttrs (config.mySystem.filesystem == "zfs") {
                    root = {
                      name = "root";
                      content = {
                        type = "zfs";
                        pool = "rpool";
                      };
                    } // lib.optionalAttrs (cfg.swapSize != null) { end = "-${cfg.swapSize}"; };
                  };
              };
            };
            cache = lib.mkIf (cfg.cacheDiskDev != null && (builtins.length cfg.tankDiskDevs > 0)) {
              device = cfg.cacheDiskDev;

              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  zfs = {
                    size = "100%";
                    content = {
                      type = "zfs";
                      pool = "tank";
                    };
                  };
                };
              };
            };
          }
          // builtins.listToAttrs (
            builtins.map (sd: {
              name = "system" + builtins.replaceStrings [ "/" ] [ "_" ] sd;
              value = {
                device = sd;

                type = "disk";
                content = {
                  type = "gpt";
                  partitions = {
                    zfs = {
                      size = "100%";
                      content = {
                        type = "zfs";
                        pool = "rpool";
                      };
                    };
                  };
                };
              };
            }) (lib.lists.drop 1 cfg.systemDiskDevs)
          )
          // builtins.listToAttrs (
            builtins.map (td: {
              name = "tank" + builtins.replaceStrings [ "/" ] [ "_" ] td;
              value = {
                device = td;

                type = "disk";
                content = {
                  type = "gpt";
                  partitions = {
                    zfs = {
                      size = "100%";
                      content = {
                        type = "zfs";
                        pool = "tank";
                      };
                    };
                  };
                };
              };
            }) cfg.tankDiskDevs
          );
      }
      // lib.optionalAttrs (config.mySystem.filesystem == "ext4") {
        lvm_vg = {
          rpool = {
            type = "lvm_vg";
            lvs =
              {
                thinpool = {
                  size = "100%FREE";
                  lvm_type = "thin-pool";
                };
                persist = {
                  size = "1T"; # overprovision in most cases
                  lvm_type = "thinlv";
                  pool = "thinpool";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint =
                      if config.mySystem.impermanence.enable then "${config.mySystem.impermanence.persistPath}" else "/";
                    mountOptions = [
                      "defaults"
                      "noatime"
                    ];
                  };
                };
              }
              // lib.optionalAttrs config.mySystem.impermanence.enable {
                nix = {
                  size = "1T"; # overprovision in most cases
                  lvm_type = "thinlv";
                  pool = "thinpool";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/nix";
                    mountOptions = [
                      "defaults"
                      "noatime"
                    ];
                  };
                };
              };
          };
        };
      }
      // lib.optionalAttrs (config.mySystem.filesystem == "ext4" && config.mySystem.impermanence.enable) {
        nodev = {
          "/" = {
            fsType = "tmpfs";
            mountOptions = [
              "size=1G"
              "mode=0755"
            ];
          };
        };
      }
      // lib.optionalAttrs (config.mySystem.filesystem == "zfs") {
        zpool =
          {
            rpool = {
              type = "zpool";
              rootFsOptions = {
                compression = "lz4";
                atime = "off";
                "com.sun:auto-snapshot" = "false";
              };
              mountpoint = "/";
              postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^rpool@${config.mySystem.impermanence.zfsRootBlankSnapshotName}$' || zfs snapshot rpool@${config.mySystem.impermanence.zfsRootBlankSnapshotName}";
              datasets =
                cfg.systemDatasets
                // lib.optionalAttrs
                  (config.mySystem.impermanence.enable && config.mySystem.impermanence.zfsPool == "rpool")
                  {
                    persist = {
                      type = "zfs_fs";
                      mountpoint = "${config.mySystem.impermanence.persistPath}";
                    };
                  };
            };
          }
          // lib.optionalAttrs (builtins.length cfg.tankDiskDevs > 0) {
            tank = {
              type = "zpool";
              mode = lib.mkIf (builtins.length cfg.tankDiskDevs > 1) {
                topology = {
                  type = "topology";
                  vdev = [
                    {
                      mode =
                        if builtins.length cfg.tankDiskDevs > 3 then
                          "raidz2"
                        else if builtins.length cfg.tankDiskDevs > 2 then
                          "raidz1"
                        else if builtins.length cfg.tankDiskDevs > 1 then
                          "mirror"
                        else
                          "";
                      members = builtins.map (td: ("tank" + builtins.replaceStrings [ "/" ] [ "_" ] td)) cfg.tankDiskDevs;
                    }
                  ];
                } // lib.optionalAttrs (cfg.cacheDiskDev != null) { cache = [ "cache" ]; };
              };

              rootFsOptions = {
                compression = "lz4";
                atime = "off";
                "com.sun:auto-snapshot" = "false";
              };

              mountpoint = "/tank";
              datasets =
                cfg.tankDatasets
                // lib.optionalAttrs
                  (config.mySystem.impermanence.enable && config.mySystem.impermanence.zfsPool == "tank")
                  {
                    persist = {
                      type = "zfs_fs";
                      # impermanence.nix user `fileSystems."/persist"....` stanza, which will collide with ZFS mount system,
                      # and mail fail at boot. "legacy" delegates mounting to the OS, and allows to boot properly.
                      mountpoint = "legacy";
                    };
                  };
            };
          };
      };
  };
}
