{ config, ... }:
let
  backupsPath = "/mnt/tank/backups";
  mediaPath = "/mnt/tank/media";
  privatePath = "/mnt/tank/private";

  booksPath = "${mediaPath}/books";
  musicPath = "${mediaPath}/music";
  romsPath = "${mediaPath}/retrom";
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
      systemDiskDevs = [ "/dev/vda" ];
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
      machineId = "bf52c8ab338949159f545637a879e23c";
      persistPath = "/persist";
      zfsPool = "rpool";
    };

    mounts = [
      {
        type = "nfs";
        src = "${config.myInfra.machines.meemee.ip}:/mnt/tank/backups";
        dest = "/mnt/tank/backups";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.meemee.ip}:/mnt/tank/old-media";
        dest = "/mnt/tank/media";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.meemee.ip}:/mnt/tank/private/Dokumenty";
        dest = "/mnt/tank/private/Dokumenty";
      }
    ];

    networking = {
      enable = true;
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "deedee";
      mainInterface = {
        name = "ens3";
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
        privatePath
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

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
      # extraVHosts = {
      #   obsidian = {
      #     target = "http://minio.docker:9000/assets/obsidian$request_uri";
      #     extraConfig = ''rewrite ^(.*)/$ https://obsidian.${mySystem.rootDomain}''$1/index.html break;'';
      #   };
      # };
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
    calibre-web-automated = {
      inherit booksPath;

      enable = true;
    };
    coredns.enable = true;
    # crypt.enable = true; # because registry
    davis = {
      enable = true;
      carddavEnable = true;
      caldavEnable = false;
      webdavEnable = true;
      webdavDir = "${mediaPath}/webdav";
      webdavDirBackup = false;
    };
    filebrowser = {
      enable = true;
      subdomain = "nas";
      sources = {
        "${backupsPath}" = {
          path = backupsPath;
          name = "backups";
        };
        "${privatePath}" = {
          path = privatePath;
          name = "private";
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
    n8n = {
      enable = true;
      enablePatches = true;
      integrations = [
        # "grist"
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
        business = "${privatePath}/Dokumenty/Firma";
        banks = "${privatePath}/Dokumenty/Banki";
        externalBackups = "${privatePath}/Dokumenty/tmp-sync";
        flats = "${privatePath}/Dokumenty/Mieszkania";
      };
    };
    navidrome = {
      inherit musicPath;
      enable = true;
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
