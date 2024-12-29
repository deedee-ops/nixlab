_:
let
  adguardCustomMappings = builtins.fromJSON (builtins.readFile ../domains.json);
  nasIP = "10.100.10.1";
  ownIP = "10.100.20.2";
  zigbeeBottomFloorIP = "10.210.10.10";
in
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
    inherit nasIP;

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
        src = "${mySystem.nasIP}:/volume2/backup/meemee";
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
      customMappings = adguardCustomMappings;
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
        "10.100.0.0/16"
        "10.250.1.0/24"
      ];
      advertisedDNSServer = ownIP;
      externalHost = "homelab.${mySystem.rootDomain}";
      wireguardPort = 53201;
    };
    zigbee2mqtt = {
      enable = true;
      extraConfigs = {
        # topfloor = {
        #   advanced = {
        #     transmit_power = 20;
        #   };
        #   serial = {
        #     port = "/dev/ttyUSB0";
        #     disable_led = false;
        #     baudrate = 115200;
        #   };
        # };
        bottomfloor = {
          serial = {
            port = "tcp://${zigbeeBottomFloorIP}:6638";
            baudrate = 115200;
            adapter = "ezsp";
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
