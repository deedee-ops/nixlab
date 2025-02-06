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
      };
      secondaryInterface = {
        name = "enp4s0";
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
      enableDoH = true;
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
      extraVHosts = {
        minio = "http://${config.myInfra.machines.nas.ip}:9001";
        registry = "http://${config.myInfra.machines.nas.ip}:5555";
        s3 = "http://${config.myInfra.machines.nas.ip}:9000";
      };
      extraRedirects = {
        kvm-deedee = "http://${config.myInfra.machines.kvm-deedee.ip}";
      };
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
              port = "tcp://${config.myInfra.devices.slzb06m-top.ip}:6638";
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
    zellij.enable = true;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
