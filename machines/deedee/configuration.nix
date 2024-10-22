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

  mySystem = {
    filesystem = "zfs";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    rootDomain = "rzegocki.dev";
    nasIP = "10.100.10.1";
    notificationEmail = "homelab@${mySystem.rootDomain}";
    notificationSender = "deedee@${mySystem.rootDomain}";

    disks = {
      enable = true;
      hostId = "d732cc87";
      swapSize = "4G";
      systemDiskDevs = [ "/dev/sda" ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
        vms = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
      };
    };

    impermanence = {
      enable = true;
      persistPath = "/persist";
    };

    networking = {
      enable = true;
      firewallEnable = false;
      hostname = "deedee";
      mainInterface = "enp5s0";
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
      domains = [
        mySystem.rootDomain
        "*.${mySystem.rootDomain}"
      ];
    };

    maddy = {
      enable = true;
      envFileSopsSecret = "system/apps/maddy/envfile";
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
    authelia = {
      enable = true;
      sopsSecretPrefix = "system/apps/authelia/env";
    };

    lldap = {
      enable = true;
      sopsSecretPrefix = "system/apps/lldap/env";
    };
  };

  myApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
