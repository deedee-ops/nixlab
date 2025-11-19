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
    filesystem = "btrfs";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    notificationEmail = "homelab@rzegocki.dev";
    notificationSender = "deedee@rzegocki.dev";
    disableModules = [ "uvcvideo" ];
    trustedRootCertificates = [
      ''
        -----BEGIN CERTIFICATE-----
        MIIClDCCAhqgAwIBAgIUOfIRdHEUj5dZX1nj+QCHnTSx/pMwCgYIKoZIzj0EAwIw
        eTELMAkGA1UEBhMCUEwxFDASBgNVBAgMC21hbG9wb2xza2llMQ8wDQYDVQQHDAZL
        cmFrb3cxEDAOBgNVBAoMB2hvbWVsYWIxEDAOBgNVBAMMB1Jvb3QgQ0ExHzAdBgkq
        hkiG9w0BCQEWEGlnb3JAcnplZ29ja2kucGwwHhcNMjUxMTE3MjAyNDMxWhcNMzUx
        MTE1MjAyNDMxWjB5MQswCQYDVQQGEwJQTDEUMBIGA1UECAwLbWFsb3BvbHNraWUx
        DzANBgNVBAcMBktyYWtvdzEQMA4GA1UECgwHaG9tZWxhYjEQMA4GA1UEAwwHUm9v
        dCBDQTEfMB0GCSqGSIb3DQEJARYQaWdvckByemVnb2NraS5wbDB2MBAGByqGSM49
        AgEGBSuBBAAiA2IABP8xPh+ljvtqRZqdCegByaeqYe3gAc6kNxo3vEtp+dcwwZz6
        w+liyGQUfDlResruYE2YZZfWVMjZv+GG1afM3jOFIhPYPBZo2bbBshBcXflfASQ8
        d4EJSNMqUwC8OxuzsKNjMGEwHQYDVR0OBBYEFO+sxaxJd7J/Dohxd0y/Z6lWYE43
        MB8GA1UdIwQYMBaAFO+sxaxJd7J/Dohxd0y/Z6lWYE43MA8GA1UdEwEB/wQFMAMB
        Af8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMCA2gAMGUCMQCetLE7ep2PmTix
        WsTVZdp4hOxK0ewV+fHBQcV6Ra9rdPW/AAp4kNML1AdKjG+Kh3sCMGW7Oy8yuX4J
        UiFH8cVR77uVAAP0OfMsKezfDUSIadbDZCJfzkkKwDYrZMQFw1BjqA==
        -----END CERTIFICATE-----
      ''
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
    # plymouth.enable = true;
    tailscale = {
      enable = true;
      backup = false;
    };

    xorg = {
      enable = true;
      windowManager = "awesome";
    };
  };

  myHomeApps = {
    extraPackages = [
      (pkgs.callPackage ../../modules/pkgs/portwarden.nix {
        # yup, hardcoding salt sucks, but have to do it, otherwise will end up with impure package
        salt = "AhWD78cPGFqrywQGIda9PYMdzQzGzTOHzRvGh2ztqplEGaNHkqKPAeXOwSrN76M1Po3d8aYtygVEiLTIN5fizA";
      })
    ];

    scripts = {
      docwatcher = {
        enable = true;
        watchDir = "${homeDir}/Sync/docwatcher-costs";
        rclone = {
          enable = true;
          target = "'dropbox:Apps/wfirma.pl/OCR/Do Odczytu'";
        };
        mail.enable = false;
        paperless = {
          enable = true;
          consumeDir = "${config.mySystem.impermanence.persistPath}${homeDir}/Sync/paperless-consume";
        };
        ssh = {
          enable = true;
          host = "nas";
          targetDir = "/volume3/private/Memories/Private/Firma/%Y/%m/koszty";
        };
      };
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
          signing = {
            key = "igor@rzegocki.pl";
            signByDefault = true;
          };
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
    minio-client.enable = true;
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
            hostname = lib.lists.head (lib.strings.splitString ":" config.myInfra.machines.deedee.ssh);
            identitiesOnly = true;
            identityFile = [ config.sops.secrets."credentials/ssh/private_key".path ];
            port = lib.strings.toIntBase10 (
              lib.lists.last (lib.strings.splitString ":" config.myInfra.machines.deedee.ssh)
            );
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
      syncAddress = "https://atuin.rzegocki.dev";
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
    };
    syncthing.enable = true;
    teams.enable = true;
    telegram.enable = true;
    thunderbird.enable = true;
    todoist.enable = true;
    wakatime = {
      enable = true;
      wakapi.url = "https://wakapi.rzegocki.dev";
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
