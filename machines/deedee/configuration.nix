{ config, ... }:
rec {
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "cloudflare/lego_config" = { };
    };
  };

  mySystem = {
    filesystem = "zfs";
    primaryUser = "ajgon";
    rootDomain = "rzegocki.dev";
    notificationEmail = "homelab@${mySystem.rootDomain}";

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

    networking = {
      enable = true;
      firewallEnable = true;
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
    letsencrypt = {
      enable = true;
      cloudflareEnvironmentFile = config.sops.secrets."cloudflare/lego_config".path;
      domains = [
        mySystem.rootDomain
        "*.${mySystem.rootDomain}"
      ];
    };

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
    };

    # services
    homepage = {
      enable = true;
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
