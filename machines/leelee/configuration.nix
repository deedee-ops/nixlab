_: rec {
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
    purpose = "Sandbox for testing";
    filesystem = "ext4";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";

    backup = {
      locals = [
        {
          name = "tank";
          location = "/mnt/backup";
          passFileSopsSecret = "backups/restic/local/password";
        }
      ];
    };

    disks = {
      enable = true;
      hostId = "a2c58a91";
      swapSize = "4G";
      systemDiskDevs = [ "/dev/sda" ];
    };

    impermanence = {
      enable = true;
      persistPath = "/persist";
    };

    networking = {
      enable = true;
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "leelee";
      mainInterface = {
        name = "enp5s0";
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

  myHomeApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;
    zellij.enable = true;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
