{
  config,
  lib,
  pkgs,
  ...
}:
rec {
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    age.keyFile = "/persist/etc/age/keys.txt";
    secrets = {
      "credentials/gpg/key" = {
        owner = mySystem.primaryUser;
      };
      "credentials/system/ajgon" = { };
      "credentials/ssh/private_key" = {
        owner = mySystem.primaryUser;
      };
      "home/apps/ssh/extraconfig" = {
        owner = mySystem.primaryUser;
      };
    };
  };

  myHardware = {
    battery = {
      enable = true;
      chargeUpperLimit = 80;
    };
    bluetooth.enable = true;
    sound.enable = true;
  };

  mySystem = {
    purpose = "Laptop";
    filesystem = "zfs";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    notificationEmail = "homelab@rzegocki.dev";
    notificationSender = "deedee@rzegocki.dev";

    alerts = {
      pushover.enable = true;
    };

    disks = {
      enable = true;
      hostId = "d453adff";
      swapSize = "4G";
      systemDiskDevs = [
        "/dev/disk/by-id/nvme-Micron_2400_MTFDKBA512QFM_234143E75C14"
      ];
      systemDatasets = {
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
    };

    grub.enable = true;

    impermanence = {
      enable = true;
      machineId = "8cb0c97e3fa0c35b006411c366cca589";
      persistPath = "/persist";
      zfsPool = "rpool";
    };

    networking = {
      enable = true;
      wifiSupport = true;
      firewallEnable = true;
      hostname = "liadtop";
      mainInterface = {
        name = "wlp1s0";
      };
      # ensure that homelab is available even if local DNS dies
      extraHosts = ''
        10.100.20.1 deedee.home.arpa
        10.100.20.2 meemee.home.arpa
        10.200.10.10 monkey.home.arpa
      '';
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
    docker = {
      enable = true;
      rootless = false;
    };
    # plymouth.enable = true;

    xorg = {
      enable = true;
      windowManager = "awesome";
    };
  };

  myHomeApps = {
    shellInitScriptFiles = [
      (lib.getExe (
        pkgs.writeShellScriptBin "pdf.sh" (
          ''
            magick_cmd="${lib.getExe pkgs.imagemagick}"
            gs_cmd="${lib.getExe pkgs.ghostscript_headless}"
          ''
          + builtins.readFile ./scripts/pdf.sh
        )
      ))
    ];

    aichat.enable = true;
    git = {
      appendOptions = {
        userName = "Igor Rzegocki";
        userEmail = "igor@rzegocki.pl";
        signing = {
          key = "igor@rzegocki.pl";
          signByDefault = true;
        };
      };
    };
    gnupg = {
      publicKeys = [ ./public.gpg ];
      privateKeys = [
        {
          inherit (config.sops.secrets."credentials/gpg/key") path;

          id = "igor@rzegocki.pl";
        }
      ];
      rememberPasswordTime = 28800;
    };
    qrtools.enable = true;
    speedcrunch.enable = true;
    ssh = {
      appendOptions = {
        includes = [
          config.sops.secrets."home/apps/ssh/extraconfig".path
        ];
        matchBlocks = {
          # private
          deedee = {
            forwardAgent = true;
            host = "deedee";
            hostname = "deedee.home.arpa";
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = 22;
            user = "ajgon";
          };
          forgejo = {
            forwardAgent = false;
            host = "git.rzegocki.dev";
            hostname = "git.rzegocki.dev";
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = 2222;
            user = "git";
          };
          meemee = {
            forwardAgent = true;
            host = "meemee";
            hostname = "meemee.home.arpa";
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = 22;
            user = "ajgon";
          };
          nas = {
            forwardAgent = false;
            host = "nas";
            hostname = "nas.home.arpa";
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = 51008;
            user = "ajgon";
          };

          # public
          github = {
            forwardAgent = false;
            host = "github.com";
            hostname = "github.com";
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = 22;
            user = "git";
          };
        };
      };
    };

    theme = {
      terminalFontSize = 9;
    };
    awesome = {
      enable = true;
      singleScreen = true;
    };
    caffeine.enable = true;
    discord.enable = true;
    firefox = {
      enable = true;
      startupPage = "https://www.rzegocki.dev/";
      syncServerUrl = "https://firefoxsync.rzegocki.dev";
      whoogleSearch = {
        enable = true;
        url = "https://whoogle.rzegocki.dev";
      };
    };
    mpv.enable = true;
    obsidian.enable = true;
    redshift = {
      enable = true;
      latitude = 50.061389;
      longitude = 19.938333;
    };
    rofi = {
      enable = true;
      passwordManager = "bitwarden";
      bitwarden = {
        email = "bitwarden@ajgon.ovh";
        base_url = "https://vault.bitwarden.eu/";
      };
    };
    syncthing.enable = true;
    teams.enable = true;
    telegram.enable = true;
    thunderbird.enable = true;
    ticktick.enable = true;
    wakatime = {
      enable = true;
      wakapi.url = "https://wakapi.rzegocki.dev";
    };
    whatsie.enable = true;
    xorg = {
      autorandr = { };
      mapRightCtrlToAltGr = true;
      terminal = pkgs.kitty;
      trackpadSupport = true;
    };
    zathura.enable = true;
    zsh.promptColor = "magenta";
  };

  system.stateVersion = "24.11";
}
