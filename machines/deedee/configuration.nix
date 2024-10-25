_: rec {
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "credentials/services/admin" = {
        mode = "0440";
        group = "services";
      };
      "credentials/system/ajgon" = { };
    };
  };

  mySystem = rec {
    purpose = "Homelab";
    filesystem = "zfs";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    rootDomain = "rzegocki.dev";
    nasIP = "10.100.10.1";
    notificationEmail = "homelab@${mySystem.rootDomain}";
    notificationSender = "deedee@${mySystem.rootDomain}";

    alerts = {
      pushover = {
        enable = true;
        envFileSopsSecret = "alerts/pushover/env";
      };
    };

    autoUpgrade.enable = true;

    backup = {
      local = {
        enable = true;
        location = "/mnt/backup";
      };
      remote = {
        enable = true;
        repositoryFileSopsSecret = "backups/restic/remoterepo";
      };
      passFileSopsSecret = "backups/restic/password";
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

    impermanence = {
      enable = true;
      persistPath = "/persist";
      zfsPool = "tank";
    };

    mounts = [
      {
        type = "nfs";
        src = "${nasIP}:/volume2/backup/deedee";
        dest = backup.local.location;
      }
    ];

    networking = {
      enable = true;
      firewallEnable = false;
      hostname = "deedee";
      mainInterface = "enp87s0";
    };

    nix = {
      githubPrivateTokenSopsSecret = "credentials/github/access-token-nix-config";
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
    };

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

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
      extraVHosts = {
        s3 = "http://${mySystem.nasIP}:9000";
        minio = "http://${mySystem.nasIP}:9001";
        nas = "http://${mySystem.nasIP}:5000";
      };
    };

    postgresql.enable = true;
    redis = {
      enable = true;
      passFileSopsSecret = "system/apps/redis/password";
    };

    # containers
    authelia.enable = true;
    coredns.enable = true;
    maddy.enable = true;
    lldap.enable = true;
    vaultwarden.enable = true;
    wakapi.enable = true;
  };

  myApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
