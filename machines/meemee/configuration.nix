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

  myHardware = {
    nvidia = {
      enable = true;
      useOpenDrivers = true;
      forceCompileCUDA = true;
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

    disks = {
      enable = true;
      hostId = "f7420887";
      swapSize = "4G";
      systemDiskDevs = [ "/dev/disk/by-id/nvme-Patriot_P300_1TB_AA000000000000000047" ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
    };

    healthcheck.enable = true;
    impermanence.enable = false;

    networking = {
      enable = true;
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "meemee";
      mainInterface = {
        name = "enp6s0";
        bridge = true;
        bridgeMAC = "02:00:0a:64:14:02";
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
    docker = {
      enable = true;
      rootless = false;
      pruneAll = true;
    };

    incus = {
      enable = true;
      enableUI = true;
      enablePassthrough = true;
      subdomain = "incus-gpu";
      initializeBaseNixOSVM = true;
      defaultStoragePool = {
        config = {
          source = "rpool/vms";
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
      ];
    };

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
    };

    ollama = {
      enable = true;
      loadModels = [
        "gemma3"
        "gpt-oss:20b"
      ];
      exposePort = true;
    };

    # containers
    coredns.enable = true;
    comfyui.subdomain = "comfy";
    jupyter.enable = true;
    open-webui = {
      enable = true;
      generateImages = true;
      subdomain = "ai";
    };
  };

  myHomeApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;
    zellij.enable = true;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "25.11";
}
