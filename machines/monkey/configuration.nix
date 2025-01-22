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
      enableBluemanApplet = false;
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

    # can introduce some unexpected changes, especially in chiaki-ng
    # better do it manually via deployments
    autoUpgrade.enable = false;

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
        command = lib.getExe (
          pkgs.writeShellScriptBin "kiosk-chiaki" ''
            (
              while [ -z "$(${lib.getExe pkgs.lsof} -nPi @${config.myInfra.devices.ps5.ip}:9295 | grep ESTABLISHED)" ]; do sleep 1; done;
              sleep 10
              while [ -n "$(${lib.getExe pkgs.lsof} -nPi @${config.myInfra.devices.ps5.ip}:9295 | grep ESTABLISHED)" ]; do sleep 1; done;
              ${lib.getExe' pkgs.systemd "systemctl"} poweroff
            ) &

            $XDG_DATA_HOME/Chiaki/chiaki-start
          ''
        );
      };
    };
  };

  myHomeApps = {
    chiaki-ng.enable = true;
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "24.11";
}
