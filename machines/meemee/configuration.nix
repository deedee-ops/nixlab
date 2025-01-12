{ config, ... }:
rec {
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "credentials/services/admin" = {
        mode = "0440";
        group = "services";
      };
      "credentials/system/ajgon" = { };
    };
  };

  mySystem = {
    purpose = "Smart Home";
    filesystem = "zfs";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    rootDomain = "rzegocki.dev";
    notificationEmail = "homelab@${mySystem.rootDomain}";
    notificationSender = "deedee@${mySystem.rootDomain}";

    alerts = {
      pushover.enable = true;
    };

    autoUpgrade.enable = true;

    backup = {
      local = {
        enable = true;
        location = "/mnt/backup";
        passFileSopsSecret = "backups/restic/local/password";
      };
      remotes = [
        {
          name = "borgbase-eu";
          location = "rest:https://x49pyrz3.repo.borgbase.com";
          envFileSopsSecret = "backups/restic/repo-borgbase-eu/env";
          passFileSopsSecret = "backups/restic/repo-borgbase-eu/password";
        }
        {
          name = "borgbase-us";
          location = "rest:https://rr742mx3.repo.borgbase.com";
          envFileSopsSecret = "backups/restic/repo-borgbase-us/env";
          passFileSopsSecret = "backups/restic/repo-borgbase-us/password";
        }
      ];
    };

    disks = {
      enable = true;
      hostId = "bec09da4";
      swapSize = "4G";
      systemDiskDevs = [ "/dev/sda" ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
    };

    extraUdevRules = ''
      # disable usb autosuspend for USB ethernet dongle
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8153", TEST=="power/control", ATTR{power/control}="on"
    '';

    healthcheck.enable = true;

    impermanence = {
      enable = true;
      machineId = "b14c15cd293ed31307c9ebb94c2b6dec";
      persistPath = "/persist";
    };

    mounts = [
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/volume2/backup/meemee";
        dest = mySystem.backup.local.location;
      }
    ];

    networking = {
      enable = true;
      firewallEnable = true;
      hostname = "meemee";
      mainInterface = {
        name = "enp3s0";
        DNS = [
          "9.9.9.9"
          "149.112.112.10"
        ];
      };
      secondaryInterface = {
        name = "enp4s0";
        DNS = [
          "9.9.9.9"
          "149.112.112.10"
        ];
      };
    };

    ssh = {
      enable = true;
      authorizedKeys = {
        "${mySystem.primaryUser}" = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrBLT88ZZ+lO8hHcj+4jqtor79OLhQZcDWF98kkWkfn personal"
        ];
      };
    };
  };

  mySystemApps = {
    adguardhome = {
      enable = true;
      adminPasswordSopsSecret = "credentials/services/admin";
      subdomain = "adguard-meemee";
    };

    ddclient.enable = true;

    docker = {
      enable = true;
      rootless = false;
      pruneAll = true;
    };

    letsencrypt = {
      enable = true;
      useProduction = true;
      domains = [
        mySystem.rootDomain
        "*.${mySystem.rootDomain}"
      ];
    };

    mosquitto.enable = true;

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
    };

    # containers
    coredns.enable = true;
    home-assistant.enable = true;
    homepage = {
      enable = true;
      title = "meemee";
      disks = {
        DATA = "/";
      };
      subdomain = "meemee";
      services.Hosts = {
        deedee = {
          icon = "netboot.svg";
          href = "https://deedee.${mySystem.rootDomain}";
        };
        meemee = {
          icon = "netboot.svg";
          href = "https://meemee.${mySystem.rootDomain}";
        };
      };
    };
    maddy.enable = true;
    wg-easy = {
      enable = true;
      allowedCIDRs = [
        config.myInfra.cidrs.trusted
        config.myInfra.cidrs.wireguard
      ];
      advertisedDNSServer = config.myInfra.machines.meemee.ip;
      externalHost = "homelab.${mySystem.rootDomain}";
      wireguardNetworkCIDR = config.myInfra.cidrs.wireguard;
      wireguardPort = 53201;
    };
    zigbee2mqtt = {
      enable = true;
      coordinators = {
        topfloor = {
          envFileSopsSecret = "system/apps/zigbee2mqtt/topfloor/envfile";
          config = {
            advanced = {
              transmit_power = 20;
            };
            serial = {
              port = "/dev/serial/by-id/usb-SMLIGHT_SMLIGHT_SLZB-06M_149444ac1ca6ed118ab2e8a32981d5c7-if00-port0";
              baudrate = 115200;
              adapter = "ember";
            };
          };
        };
        bottomfloor = {
          envFileSopsSecret = "system/apps/zigbee2mqtt/bottomfloor/envfile";
          config = {
            advanced = {
              transmit_power = 20;
            };
            serial = {
              port = "tcp://${config.myInfra.devices.slzb06m-bottom.ip}:6638";
              baudrate = 115200;
              adapter = "ember";
            };
          };
        };
      };
    };
  };

  myHomeApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
