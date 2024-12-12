_:
let
  mediaPath = "/mnt/media";
  audiobooksPath = "${mediaPath}/audiobooks";
  photosPath = "${mediaPath}/photos";
  podcastsPath = "${mediaPath}/podcasts";
  torrentsPath = "${mediaPath}/torrents";
  videoPath = "${mediaPath}/video";

  gwIP = "192.168.100.1";
  nasIP = "10.100.10.1";
  omadaIP = "10.100.1.1";

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

    purpose = "Homelab";
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
          location = "rest:https://pyif3th7.repo.borgbase.com";
          envFileSopsSecret = "backups/restic/repo-borgbase-eu/env";
          passFileSopsSecret = "backups/restic/repo-borgbase-eu/password";
        }
        {
          name = "borgbase-us";
          location = "rest:https://p51to40o.repo.borgbase.com";
          envFileSopsSecret = "backups/restic/repo-borgbase-us/env";
          passFileSopsSecret = "backups/restic/repo-borgbase-us/password";
        }
      ];
    };

    disks = {
      enable = true;
      hostId = "d732cc87";
      swapSize = "4G";
      systemDiskDevs = [ "/dev/disk/by-id/nvme-Patriot_Scorch_M2_288E079211DE06830897" ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
      tankDiskDevs = [ "/dev/disk/by-id/nvme-KINGSTON_OM8PGP41024Q-A0_50026B7382DA5EF6" ];
      tankDatasets = {
        vms = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
      };
    };

    healthcheck.enable = true;

    impermanence = {
      enable = true;
      machineId = "bf52c8ab338949159f545637a879e23c";
      persistPath = "/persist";
      zfsPool = "tank";
    };

    mounts = [
      {
        type = "nfs";
        src = "${mySystem.nasIP}:/volume2/backup/deedee";
        dest = mySystem.backup.local.location;
      }
      {
        type = "nfs";
        src = "${mySystem.nasIP}:/volume1/media/music";
        dest = mySystemApps.navidrome.musicPath;
        opts = "ro";
      }
      {
        type = "nfs";
        src = "${mySystem.nasIP}:/volume1/media";
        dest = mySystemApps.radarr.mediaPath;
      }
    ];

    networking = {
      enable = true;
      firewallEnable = true;
      hostname = "deedee";
      mainInterface = {
        name = "enp87s0";
        bridge = true;
        bridgeMAC = "02:00:0a:64:14:01";
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
      subdomain = "adguard-deedee";
    };

    ddclient.enable = true;

    docker = {
      enable = true;
      rootless = false;
    };

    incus = {
      enable = true;
      enableUI = true;
      initializeBaseNixOSVM = true;
      defaultStoragePool = {
        config = {
          source = "tank/vms";
        };
        driver = "zfs";
      };
      defaultNIC = {
        nictype = "bridged";
        parent = "br0";
        type = "nic";
      };
    };

    letsencrypt = {
      enable = true;
      useProduction = true;
      domains = [
        mySystem.rootDomain
        "*.${mySystem.rootDomain}"
      ];
    };

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
      extraVHosts = {
        minio = "http://${mySystem.nasIP}:9001";
        nas = "http://${mySystem.nasIP}:5000";
        s3 = "http://${mySystem.nasIP}:9000";

        omada = "https://${omadaIP}";
      };
      extraRedirects = {
        gw = "http://${gwIP}";
        www = "https://deedee.${mySystem.rootDomain}";
      };
    };

    postgresql.enable = true;
    redis.enable = true;
    rustdesk = {
      enable = true;
      relayHost = "relay.${mySystem.rootDomain}";
    };

    # containers
    audiobookshelf = {
      inherit audiobooksPath podcastsPath;
      enable = true;
    };
    authelia.enable = true;
    bazarr = {
      inherit videoPath;
      enable = true;
    };
    coredns.enable = true;
    echo-server.enable = false;
    firefoxsync.enable = true;
    firefly-iii.enable = true;
    flaresolverr.enable = true;
    forgejo.enable = true;
    gluetun = {
      enable = true;
      forwardedPort = 17307;
    };
    homepage = {
      enable = true;
      title = "deedee";
      disks = {
        DATA = "/";
      };
      subdomain = "deedee";
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
    immich = {
      inherit photosPath;
      enable = true;
      dataPath = "/mnt/media/immich";
    };
    jellyfin = {
      inherit videoPath;
      enable = true;
    };
    lldap.enable = true;
    maddy.enable = true;
    mail-archive.enable = true;
    miniflux.enable = true;
    navidrome = {
      enable = true;
      musicPath = "/mnt/music";
    };
    paperless-ngx.enable = true;
    piped.enable = true;
    prowlarr.enable = true;
    qbittorrent = {
      enable = true;
      downloadsPath = torrentsPath;
    };
    radarr = {
      inherit mediaPath;
      enable = true;
    };
    recyclarr.enable = true;
    redlib.enable = true;
    sonarr = {
      inherit mediaPath;
      enable = true;
    };
    syncthing.enable = true;
    tika.enable = true;
    vaultwarden.enable = true;
    vikunja.enable = false;
    wakapi.enable = true;
    whoogle.enable = true;
  };

  myHomeApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
