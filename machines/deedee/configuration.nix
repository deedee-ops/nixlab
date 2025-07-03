{ config, ... }:
let
  dataPath = "/tank/data";
  mediaPath = "/tank/media";
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
          location = "${dataPath}/backups";
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
      systemDiskDevs = [ "/dev/disk/by-id/nvme-Patriot_M.2_P300_256GB_P300NDBB24031803163" ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
      tankDiskDevs = [ "/dev/disk/by-id/ata-WD_Blue_SA510_2.5_4TB_24404UD00701" ];
      tankDatasets = {
        data = {
          type = "zfs_fs";
        };
        media = {
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

    networking = {
      enable = true;
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "deedee";
      mainInterface = {
        name = "eno1";
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
      "tank/data" = { };
      "tank/webdav" = { };
    };
  };

  mySystemApps = {
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
      syncCerts.unifi = "wildcard.${mySystem.rootDomain}";
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

    postgresql.enable = true;
    redis.enable = true;

    # containers
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
    firefoxsync.enable = true;
    firefly-iii.enable = true;
    forgejo = {
      enable = true;
      enableRunner = true;
    };
    homepage = {
      enable = true;
      title = "deedee";
      disks = {
        DATA = "/";
      };
      subdomain = "deedee";
    };
    # immich = {
    #   enable = true;
    #   dataPath = "${mediaPath}/immich";
    # };
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
        }
        {
          name = "forgejo";
          backup = true;
          public = false;
          owner = "forgejo";
        }
        {
          name = "nix";
          backup = false;
          public = true;
          owner = "nixcache";
        }
        {
          name = "registry";
          backup = false;
          public = false;
          owner = "registry";
        }
        {
          name = "states";
          backup = true;
          public = false;
          owner = "states";
        }
      ];
    };
    paperless-ngx.enable = true;
    registry = {
      enable = true;
      enableUI = true;
    };
    syncthing.enable = true;
    tika.enable = true;
    wakapi.enable = true;
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

  system.stateVersion = "25.11";
}
