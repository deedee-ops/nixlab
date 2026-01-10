{
  config,
  pkgs,
  lib,
  ...
}:
let
  homeDir = config.home-manager.users."${config.mySystem.primaryUser}".home.homeDirectory;
in
rec {
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    age.keyFile = "${
      if mySystem.impermanence.enable then mySystem.impermanence.persistPath else ""
    }/etc/age/keys.txt";
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
      kernelModule = "asus-nb-wmi";
      chargeLimit = {
        top = 80;
        bottom = 20;
      };
    };
    bluetooth.enable = true;
    radeon.enable = true;
    sound.enable = true;
  };

  mySystem = {
    purpose = "Laptop";
    filesystem = "ext4";
    primaryUser = "ajgon";
    primaryUserExtraDirs = [
      "/mnt"
    ];
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    notificationEmail = "homelab@rzegocki.dev";
    notificationSender = "deedee@rzegocki.dev";
    disableModules = [ "uvcvideo" ];
    trustedRootCertificates = [
      (builtins.readFile ../../assets/ca-ec384.crt)
      (builtins.readFile ../../assets/ca-rsa4096.crt)
    ];

    alerts = {
      pushover.enable = true;
    };

    disks = {
      enable = true;
      hostId = "d453adff";
      swapSize = "24G"; # For hibernation swap = 1.5 x RAM is recommended
      systemDiskDevs = [
        "/dev/disk/by-id/nvme-Micron_2400_MTFDKBA512QFM_234143E75C14"
      ];
    };

    grub = {
      enable = true;
      efiInstallAsRemovable = true;
    };

    impermanence.enable = false;

    mounts = [
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/mnt/tank/private";
        dest = "/mnt/tank/private";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/mnt/tank/private/Dokumenty";
        dest = "/mnt/tank/private/Dokumenty";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/mnt/tank/private/Memories";
        dest = "/mnt/tank/private/Memories";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/mnt/tank/private/Photos";
        dest = "/mnt/tank/private/Photos";
        opts = "ro";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.nas.ip}:/mnt/cache/merger";
        dest = "/mnt/cache/merger";
      }
    ];

    networking = {
      enable = true;
      wifiSupport = true;
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "liadtop";
      mainInterface = {
        name = "wlp1s0";
        DNS = [
          "9.9.9.9"
          "149.112.112.112"
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
    docker = {
      enable = true;
      rootless = false;
      pruneAll = false;
    };
    tailscale = {
      enable = true;
      enableUI = true;
      backup = false;
    };

    xorg = {
      enable = true;
      windowManager = "awesome";
    };
  };

  myHomeApps = {
    extraPackages = [
      pkgs.gimp
      (pkgs.callPackage ../../modules/pkgs/portwarden.nix {
        # yup, hardcoding salt sucks, but have to do it, otherwise will end up with impure package
        salt = "AhWD78cPGFqrywQGIda9PYMdzQzGzTOHzRvGh2ztqplEGaNHkqKPAeXOwSrN76M1Po3d8aYtygVEiLTIN5fizA";
      })
    ];

    scripts = {
      backupverify.enable = true;
      pdfhelpers.enable = true;
    };

    aichat.enable = true;
    git = {
      appendOptions = {
        settings = {
          user = {
            name = "Igor Rzegocki";
            email = "igor@rzegocki.pl";
          };
        };
        signing = {
          key = "igor@rzegocki.pl";
          signByDefault = true;
        };
      };
    };
    gnupg = {
      pinentryPackage = pkgs.pinentry-qt;
      publicKeys = [ ./public.gpg ];
      privateKeys = [
        {
          inherit (config.sops.secrets."credentials/gpg/key") path;

          id = "igor@rzegocki.pl";
        }
      ];
      rememberPasswordTime = 28800;
    };
    kubernetes = {
      enable = true;
      kubeconfigSopsSecret = "home/apps/kubernetes/kubeconfig";
    };
    minio-client.enable = true;
    mitmproxy.enable = true;
    qrtools.enable = true;
    speedcrunch.enable = true;
    ssh = {
      appendOptions = {
        includes = [
          config.sops.secrets."home/apps/ssh/extraconfig".path
        ];
        matchBlocks = {
          # private
          forgejo = {
            forwardAgent = false;
            host = "git.ajgon.casa";
            hostname = "git.ajgon.casa";
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = 22;
            user = "git";
          };
          mandark = {
            forwardAgent = true;
            host = "mandark";
            hostname = lib.lists.head (lib.strings.splitString ":" config.myInfra.machines.mandark.ssh);
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = lib.strings.toIntBase10 (
              lib.lists.last (lib.strings.splitString ":" config.myInfra.machines.mandark.ssh)
            );
            user = "ajgon";
          };
          nas = {
            forwardAgent = false;
            host = "nas";
            hostname = lib.lists.head (lib.strings.splitString ":" config.myInfra.machines.nas.ssh);
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = lib.strings.toIntBase10 (
              lib.lists.last (lib.strings.splitString ":" config.myInfra.machines.nas.ssh)
            );
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

    atuin = {
      enable = true;
      syncAddress = "https://atuin.ajgon.casa";
    };
    awesome = {
      enable = true;
      singleScreen = true;
    };
    caffeine.enable = true;
    discord.enable = true;
    firefox = {
      enable = true;
      startupPage = "https://www.ajgon.casa/";
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
        email = "igor@rzegocki.pl";
        base_url = "https://vault.bitwarden.eu/";
      };
      features = {
        launcher = false;
        clipboard = false;
        windowSwitcher = false;
        sshShell = false;
        pinentry = false;
      };
    };
    syncthing.enable = true;
    teams.enable = true;
    telegram.enable = true;
    thunderbird.enable = true;
    todoist.enable = true;
    vicinae.enable = true;
    wakatime = {
      enable = true;
      wakapi.url = "https://wakapi.ajgon.casa";
    };
    xorg = {
      autorandr = { };
      mapRightCtrlToAltGr = true;
      terminal = pkgs.ghostty;
      trackpadSupport = true;
    };
    yt-dlp.enable = true;
    zathura.enable = true;
    zsh.promptColor = "magenta";
  };

  myRetro = {
    core = {
      gamepad = "dualsense";
      savesDir = "${homeDir}/Sync/retrosaves";
      screenWidth = 2560;
      screenHeight = 1600;
    };
    retrom.enable = false;
  };

  system.stateVersion = "24.11";
}
