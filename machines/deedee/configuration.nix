{ config, ... }:
let
  mediaPath = "/mnt/media";
  audiobooksPath = "${mediaPath}/audiobooks";
  booksPath = "${mediaPath}/books";
  photosPath = "${mediaPath}/photos";
  podcastsPath = "${mediaPath}/podcasts";
  torrentsPath = "${mediaPath}/torrents";
  videoPath = "${mediaPath}/video";
  youtubePath = "${mediaPath}/youtube";
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
    purpose = "Homelab";
    filesystem = "zfs";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    rootDomain = "rzegocki.dev";
    notificationEmail = "homelab@${mySystem.rootDomain}";
    notificationSender = "deedee@${mySystem.rootDomain}";
    crossBuildSystems = [ "aarch64-linux" ];

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
        webdav = {
          type = "zfs_fs";
        };
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
        src = "${config.myInfra.machines.nas.ip}:/volume1/backup/deedee";
        dest = mySystem.backup.local.location;
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/volume2/retro/retrom";
        dest = mySystemApps.retrom.romsPath;
        opts = "ro";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/volume2/media/music";
        dest = mySystemApps.navidrome.musicPath;
        opts = "ro";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/volume2/media/youtube";
        dest = mySystemApps.pinchflat.downloadsPath;
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/volume2/media";
        dest = mySystemApps.radarr.mediaPath;
      }
    ];

    networking = {
      enable = true;
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "deedee";
      mainInterface = {
        name = "enp89s0";
        bridge = true;
        bridgeMAC = "02:00:0a:64:14:01";
      };
    };

    nix.gcPeriod = "monthly"; # for github runners

    ssh = {
      enable = true;
      authorizedKeys = {
        "${mySystem.primaryUser}" = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrBLT88ZZ+lO8hHcj+4jqtor79OLhQZcDWF98kkWkfn personal"
        ];
      };
    };

    zfs.snapshots = {
      "tank/webdav" = { };
    };
  };

  mySystemApps = {
    ddclient.enable = true;

    docker = {
      enable = true;
      rootless = false;
      pruneAll = true;
    };

    github-runners = {
      enable = true;
      personalRunners = {
        "ajgon/ajgon" = {
          num = 1;
          githubTokenSopsSecret = "system/apps/github-runners/ajgon_token";
        };
      };
      orgRunners = {
        "deedee-ops" = {
          num = 3;
          githubTokenSopsSecret = "system/apps/github-runners/deedee_ops_token";
        };
      };
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
        "*.crypt.${mySystem.rootDomain}"
      ];
    };

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
      extraRedirects = {
        gw = "http://${config.myInfra.machines.gateway.ip}";
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
    atuin.enable = true;
    audiobookshelf = {
      inherit audiobooksPath podcastsPath;
      enable = true;
    };
    authelia.enable = true;
    bazarr = {
      inherit videoPath;
      enable = true;
    };
    beszel = {
      enable = true;
      mode = "both";
      rootFs = "/extra-filesystems/persist";
      monitoredFilesystems = {
        nix = "/nix";
        persist = "/persist";
        webdav = "/tank/webdav";
      };
    };
    bitmagnet.enable = true;
    calibre-web-automated = {
      inherit booksPath;

      enable = true;
    };
    coredns.enable = true;
    crypt.enable = true;
    davis = {
      enable = true;
      carddavEnable = true;
      caldavEnable = false;
      webdavEnable = true;
      webdavDir = "/tank/webdav";
      webdavDirBackup = false;
      useAuthelia = true;
    };
    echo-server.enable = false;
    firefoxsync.enable = true;
    firefly-iii.enable = true;
    forgejo = {
      enable = true;
      enableRunner = true;
    };
    gatus = {
      enable = true;
      alertEmails = [ "admin@ajgon.ovh" ];
    };
    gluetun = {
      enable = true;
      externalDomain = "deedee.airdns.org";
      forwardedPort = 17307;
    };
    homepage = {
      enable = true;
      title = "deedee";
      disks = {
        DATA = "/";
      };
      subdomain = "deedee";
    };
    immich = {
      inherit photosPath;
      enable = true;
      dataPath = "/mnt/media/immich";
    };
    jellyfin = {
      inherit videoPath youtubePath;
      enable = true;
    };
    koreader.enable = true;
    lldap.enable = true;
    maddy.enable = true;
    mail-archive.enable = true;
    miniflux.enable = true;
    navidrome = {
      enable = true;
      musicPath = "/mnt/music";
    };
    netbox.enable = true;
    paperless-ngx.enable = true;
    pinchflat = {
      enable = true;
      downloadsPath = youtubePath;
    };
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
    retrom = {
      enable = true;
      romsPath = "/mnt/retro";
    };
    sonarr = {
      inherit mediaPath;
      enable = true;
    };
    sshwifty = {
      enable = true;
      presets =
        builtins.map
          (name: {
            title = name;
            host = config.myInfra.machines."${name}".ssh;
            user = mySystem.primaryUser;
            privateKeyName = "personal";
          })
          (
            builtins.filter (name: config.myInfra.machines."${name}".ssh != null) (
              builtins.attrNames config.myInfra.machines
            )
          );
      secretKeys = [ "personal" ];
      onlyAllowPresetRemotes = false;
    };
    syncthing.enable = true;
    tika.enable = true;
    upsnap = {
      enable = true;
      subdomain = "upsnap-deedee";
    };
    vikunja.enable = false;
    wakapi.enable = true;
    wallos.enable = true;
    whoogle.enable = true;
  };

  myHomeApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;
    yt-dlp.enable = true;
    zellij.enable = true;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
