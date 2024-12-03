_:
let
  ownIP = "10.100.20.2";

  adguardCustomMappings = builtins.fromJSON (builtins.readFile ../domains.json);
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
      systemDiskDevs = [ "/dev/disk/by-id/ata-SK_hynix_SC300_M.2_2280_128GB_FJ62N588512203251" ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
    };

    healthcheck.enable = true;

    impermanence = {
      enable = true;
      machineId = "b14c15cd293ed31307c9ebb94c2b6dec";
      persistPath = "/persist";
    };

    networking = {
      enable = true;
      firewallEnable = true;
      hostname = "meemee";
      mainInterface = {
        name = "enp1s0";
        bridge = true;
        bridgeMAC = "02:00:0a:64:14:02";
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

    postgresql.enable = true;
    redis.enable = true;

    # containers
    coredns.enable = true;
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
      enable = false;
      serials = {
        topfloor = {
          port = "/dev/ttyUSB0";
          disable_led = false;
          baudrate = 115200;
        };
        # bottomfloor = {
        #   port = "tcp://<ip>:6638";
        #   baudrate = 115200;
        #   adapter = "ezsp";
        # };
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
