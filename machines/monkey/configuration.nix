{
  config,
  lib,
  pkgs,
  ...
}:
rec {
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "credentials/system/ajgon" = { };
    };
  };

  myHardware = {
    bluetooth = {
      enable = true;
      trust = [ config.myInfra.devices.dualsense.mac ];
      # sadly, wake from bluetooth doesn't work on NUCs :(
    };
    sound.enable = true;
  };

  mySystem = {
    purpose = "Forwarding media streams";
    filesystem = "zfs";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    rootDomain = "rzegocki.dev";
    extraModules = [ "hid_playstation" ];

    alerts = {
      pushover.enable = true;
    };

    autoUpgrade.enable = true;

    disks = {
      enable = true;
      hostId = "f848d6d1";
      swapSize = "4G";
      systemDiskDevs = [ "/dev/disk/by-id/nvme-Patriot_M.2_P300_256GB_P300NDBB24031803163" ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
    };

    networking = {
      enable = true;
      firewallEnable = false;
      hostname = "monkey";
      mainInterface = {
        name = "eno1";
        bridge = true;
        bridgeMAC = "02:00:0a:c8:0a:0a";
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
    plymouth.enable = true;
    xorg = {
      enable = true;
      kiosk = {
        enable = true;
        command = ''
          ${lib.getExe pkgs.bash} -c '$XDG_DATA_HOME/Chiaki/chiaki-start; ${lib.getExe' pkgs.systemd "systemctl"} poweroff'
        '';
      };
    };
  };

  myHomeApps = {
    chiaki-ng = {
      enable = true;
      autoStream = {
        enable = true;
        consoleIP = config.myInfra.devices.ps5.ip;
      };
    };
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
