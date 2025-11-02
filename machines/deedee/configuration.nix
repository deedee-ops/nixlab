{ config, lib, ... }:
let
  backupsPath = "/tank/backups";
  dataPath = "/tank/data";
  mediaPath = "/tank/media";

  booksPath = "${mediaPath}/books";
  geodataPath = "${mediaPath}/geo";
  musicPath = "${mediaPath}/music";
  romsPath = "${mediaPath}/retrom";
  torrentsPath = "${mediaPath}/torrents";
  videoPath = "${mediaPath}/video";
  youtubePath = "${mediaPath}/youtube";

  # CAREFUL! THIS WILL WIPE WHOLE DATA ON TANK ZFS IF SET TO TRUE DURING PROVISION!
  resetTankDisk = false;
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

  myHardware.i915.enable = true;

  mySystem = {
    recoveryMode = false;
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
      locals = [
        {
          name = "tank";
          location = backupsPath;
          passFileSopsSecret = "backups/restic/local/password";
        }
      ];
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
      systemDiskDevs = [ "/dev/disk/by-id/nvme-WD_Blue_SN570_500GB_22319R490212" ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
      tankDiskDevs = lib.optionals resetTankDisk [
        "/dev/disk/by-id/ata-WD_Blue_SA510_2.5_4TB_24404UD00701"
      ];
      tankDatasets = lib.optionalAttrs resetTankDisk {
        backups = {
          type = "zfs_fs";
          options.acltype = "posix";
        };
        data = {
          type = "zfs_fs";
          options.acltype = "posix";
        };
        media = {
          type = "zfs_fs";
          options.acltype = "posix";
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
      zfsPool = "rpool";
    };

    networking = {
      enable = true;
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "deedee";
      mainInterface = {
        name = "enp100s0";
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
      "tank/backups" = { };
      "tank/data" = { };
    };
  };

  mySystemApps = {
    ddclient = {
      enable = true;
      subdomains = [ "homelab" ];
    };
    docker = {
      enable = true;
      rootless = false;
      pruneAll = true;
      ensureMountedFS = [
        backupsPath
        dataPath
        mediaPath
      ];
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
      # syncCerts.unifi = "wildcard.${mySystem.rootDomain}";
    };

    nfs = {
      enable = true;
      exports = ''
        /tank/backups ${config.myInfra.machines.work.ip}/32(insecure,rw,sync,no_subtree_check,all_squash,anonuid=65000,anongid=65000) ${config.myInfra.machines.dexter.ip}/32(insecure,rw,sync,no_subtree_check,all_squash,anonuid=0,anongid=0)
        /tank/data    ${config.myInfra.machines.dexter.ip}/32(insecure,rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=65000)
        /tank/media   ${config.myInfra.machines.dexter.ip}/32(insecure,rw,sync,no_subtree_check,all_squash,anonuid=65000,anongid=65000)
        /tank/data/retro/batocera  ${config.myInfra.cidrs.trusted}(insecure,rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=65000)
        /tank/data/retro/bios      ${config.myInfra.cidrs.trusted}(insecure,rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=65000)
        /tank/data/retro/roms      ${config.myInfra.cidrs.trusted}(insecure,rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=65000)
        /tank/data/retro/saves     ${config.myInfra.cidrs.trusted}(insecure,rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=65000)
      '';
    };

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
      extraVHosts = {
        obsidian = {
          target = "http://minio.docker:9000/assets/obsidian$request_uri";
          extraConfig = ''rewrite ^(.*)/$ https://obsidian.${mySystem.rootDomain}''$1/index.html break;'';
        };
      };
      extraRedirects = {
        gw = "http://${config.myInfra.machines.gateway.ip}";
        www = "https://deedee.${mySystem.rootDomain}";
      };
    };

    ollama = {
      enable = true;
      loadModels = [ "gemma3" ];
      exposePort = true;
    };
    postgresql.enable = true;
    redis.enable = true;

    # containers
    airtrail.enable = true;
    atuin.enable = true;
    authelia = {
      enable = true;
      users = [
        {
          username = "admin";
          email = "admin@${mySystem.rootDomain}";
          groups = [ "admins" ];
        }
        {
          username = "ajgon";
          email = "ajgon@${mySystem.rootDomain}";
        }
      ];
    };
    bazarr = {
      inherit videoPath;
      enable = true;
    };
    borgmatic = {
      enable = true;
      sourceVolumes = [ "/tank" ];
      targetVolumes = [ ];
      cacheDir = "/tank/media/_caches/borgmatic";
      repositories = {
        legacy = {
          source_directories = [ "/tank/data/legacy" ];
          repositories = [
            {
              path = "\${BORGMATIC_LEGACY_REPO_BORGBASE_EU}";
              label = "borgbase-legacy";
            }
          ];
          encryption_passphrase = "\${BORGMATIC_LEGACY_ENCRYPTION_PASSPHRASE}";
          healthchecks = {
            ping_url = "\${BORGMATIC_LEGACY_HC_PING_URL}";
          };
        };
        nas = {
          source_directories = [
            "/tank/media/music/_Mix"
            "/tank/data/materials"
            "/tank/data/private"
          ];
          repositories = [
            {
              path = "\${BORGMATIC_NAS_REPO_BORGBASE_EU}";
              label = "borgbase-nas-eu";
            }
            {
              path = "\${BORGMATIC_NAS_REPO_BORGBASE_US}";
              label = "borgbase-nas-us";
            }
          ];
          encryption_passphrase = "\${BORGMATIC_NAS_ENCRYPTION_PASSPHRASE}";
          healthchecks = {
            ping_url = "\${BORGMATIC_NAS_HC_PING_URL}";
          };
        };
      };
    };
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
      webdavDir = "${mediaPath}/webdav";
      webdavDirBackup = false;
    };
    dawarich.enable = true;
    filebrowser = {
      enable = true;
      subdomain = "nas";
      sources = {
        "${backupsPath}" = {
          path = backupsPath;
          name = "backups";
        };
        "${dataPath}" = {
          path = dataPath;
          name = "data";
        };
        "${mediaPath}" = {
          path = mediaPath;
          name = "media";
        };
      };
    };
    firefoxsync.enable = true;
    firefly-iii.enable = true;
    forgejo = {
      enable = true;
      enableRunner = true;
    };
    gatus = {
      enable = true;
      alertEmails = [ "admin@${mySystem.rootDomain}" ];
      endpoints = [
        {
          name = "unifi";
          url = "https://unifi.${mySystem.rootDomain}";
          interval = "30s";
          conditions = [ "[STATUS] < 300" ];
          alerts = [
            {
              type = "email";
              enabled = true;
            }
          ];
        }
      ];
    };
    gluetun = {
      enable = true;
      externalDomain = "deedee.airdns.org";
      forwardedPort = 17307;
    };
    grist = {
      enable = true;
      orgName = "deedee";
    };
    homepage = {
      enable = true;
      title = "deedee";
      disks = {
        DATA = "/";
      };
      subdomain = "deedee";
    };
    huntarr.enable = true;
    immich = {
      enable = true;
      dataPath = "${mediaPath}/immich";
      photosPath = "${mediaPath}/photos";
    };
    jellyfin = {
      inherit videoPath youtubePath;
      enable = true;
    };
    koreader.enable = true;
    maddy.enable = true;
    mail-archive.enable = true;
    miniflux.enable = true;
    minio = {
      enable = true;
      dataPath = "${mediaPath}/s3";
      buckets = [
        {
          name = "assets";
          backup = true;
          public = true;
          owner = "assets";
          versioned = false;
        }
        {
          name = "forgejo";
          backup = true;
          public = false;
          owner = "forgejo";
          versioned = false;
        }
        {
          name = "grist";
          backup = true;
          public = false;
          owner = "grist";
          versioned = true;
        }
        {
          name = "nix";
          backup = false;
          public = true;
          owner = "nixcache";
          versioned = false;
        }
        {
          name = "registry";
          backup = false;
          public = false;
          owner = "registry";
          versioned = false;
        }
        {
          name = "states";
          backup = true;
          public = false;
          owner = "states";
          versioned = false;
        }
      ];
    };
    n8n = {
      enable = true;
      enablePatches = true;
      integrations = [
        "grist"
        "paperless-ngx"
        "stirlingpdf"
        "syncthing"
      ];
      consumeDirs = [
        "banks"
        "bitwarden"
        "eol"
        "invoices"
        "taxes"
      ];
      targetPaths = {
        business = "${dataPath}/private/Memories/Private/Firma";
        banks = "${dataPath}/private/Memories/Private/Banki";
        externalBackups = "${dataPath}/private/Memories/Syncs";
        flats = "${dataPath}/private/Mieszkania";
      };
    };
    navidrome = {
      inherit musicPath;
      enable = true;
    };
    netbox.enable = true;
    paperless-ngx.enable = true;
    photon = {
      enable = true;
      geodataPath = "${geodataPath}/photon";
    };
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
    registry = {
      enable = true;
      enableUI = true;
    };
    retrom = {
      inherit romsPath;
      enable = true;
    };
    sonarr = {
      inherit mediaPath;
      enable = true;
    };
    stirlingpdf.enable = true;
    syncthing.enable = true;
    tailscale = {
      enable = true;
      autoProvision = true; # see option description in tailscale.nix
      advertiseRoutes = [ config.myInfra.cidrs.trusted ];
    };
    tika.enable = true;
    wakapi.enable = true;
  };

  myHomeApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;
    yt-dlp.enable = true;
    zellij.enable = true;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "25.11";
}
