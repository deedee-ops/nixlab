{ config, ... }:
let
  nasIP = "10.100.10.1";
  ownIP = "10.100.20.2";
  zigbeeBottomFloorIP = "10.210.10.10";

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
      systemDiskDevs = [ "/dev/disk/by-id/ata-SK_hynix_SC300_M.2_2280_128GB_FJ62N588512203251" ];
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
        name = "trst0";
      };
      customNetworking = {
        enable = true;
        links = {
          "0000-bridge-inherit-mac" = {
            matchConfig.Type = "bridge";
            linkConfig.MACAddressPolicy = "none";
          };
        };
        netdevs = {
          "0001-uplink" = {
            netdevConfig = {
              Kind = "bridge";
              Name = "br0";
              MACAddress = "none";
            };
            bridgeConfig = {
              # VLANFiltering = true; # when true, it breaks wireguard?
              STP = false;
            };
          };
          "0002-trst0" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "trst0";
            };
            vlanConfig.Id = 100;
          };
          "0003-untrst0" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "untrst0";
            };
            vlanConfig.Id = 200;
          };
          "0004-iot0" = {
            netdevConfig = {
              Kind = "vlan";
              Name = "iot0";
            };
            vlanConfig.Id = 210;
          };
        };
        networks = {
          "1002-add-main-to-br0" = {
            matchConfig.Name = "enp1s0";
            bridge = [ "br0" ];
            bridgeVLANs = [
              { VLAN = 100; }
              { VLAN = 200; }
              { VLAN = 210; }
            ];
          };
          "1003-br0-up" = {
            inherit (mySystem.networking.customNetworking.networks."1002-add-main-to-br0") bridgeVLANs;
            matchConfig.Name = "br0";
            vlan = [
              "trst0"
              "untrst0"
              "iot0"
            ];
            networkConfig = {
              LinkLocalAddressing = "no";
            };
          };
          "1004-trst0-up" = {
            matchConfig.Name = "trst0";
            linkConfig = {
              RequiredForOnline = "routable";
              MACAddress = "02:00:0a:64:14:02";
            };
            dhcpV4Config.UseDNS = false;
            networkConfig = {
              LinkLocalAddressing = "no"; # disable fallback IPs
              DHCP = "ipv4";
              DNS = [ "10.100.1.1" ];
            };
          };
          "1005-untrst0-up" = {
            matchConfig.Name = "untrst0";
            linkConfig = {
              RequiredForOnline = "routable";
              MACAddress = "02:00:0a:c8:14:02";
            };
            networkConfig = {
              LinkLocalAddressing = "no"; # disable fallback IPs
              DHCP = "ipv4";
            };
          };
          "1005-iot0-up" = {
            matchConfig.Name = "iot0";
            linkConfig = {
              RequiredForOnline = "routable";
              MACAddress = "02:00:0a:d2:01:f0";
            };
            networkConfig = {
              LinkLocalAddressing = "no"; # disable fallback IPs
              DHCP = "ipv4";
            };
          };
        };
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
        topfloor = {
          advanced = {
            transmit_power = 20;
          };
          serial = {
            port = "/dev/ttyUSB0";
            disable_led = false;
            baudrate = 115200;
          };
        };
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

  # @todo @hack HERE BE DRAGONS
  # this temporary hack adds retries to all remote restic backup services, until I resolve the trunking issues
  systemd.services = builtins.listToAttrs (
    builtins.map (name: {
      name = "restic-backups-${name}";
      value = {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 30;
        };
        unitConfig = {
          StartLimitInterval = 100;
          StartLimitBurst = 3;
        };
      };
    }) (builtins.attrNames config.services.restic.backups)
  );
}
