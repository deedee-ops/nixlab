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
    primaryUserExtraDirs = [
      "/mnt"
    ];
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    notificationEmail = "homelab@rzegocki.dev";
    notificationSender = "deedee@rzegocki.dev";
    disableModules = [ "uvcvideo" ];
    trustedRootCertificates = [
      # homelab main
      ''
        -----BEGIN CERTIFICATE-----
        MIICozCCAiigAwIBAgIUEYDoGF/r2MGE9j4HkcxKnoAvo1kwCgYIKoZIzj0EAwIw
        fzELMAkGA1UEBhMCUEwxFDASBgNVBAgMC21hbG9wb2xza2llMQ8wDQYDVQQHDAZL
        cmFrb3cxEDAOBgNVBAoMB2hvbWVsYWIxFjAUBgNVBAMMDXJvb3QgQ0EgRUMzODQx
        HzAdBgkqhkiG9w0BCQEWEGlnb3JAcnplZ29ja2kucGwwIBcNMjUxMTI1MTA0MzQ5
        WhgPMjEyNTExMDExMDQzNDlaMH8xCzAJBgNVBAYTAlBMMRQwEgYDVQQIDAttYWxv
        cG9sc2tpZTEPMA0GA1UEBwwGS3Jha293MRAwDgYDVQQKDAdob21lbGFiMRYwFAYD
        VQQDDA1yb290IENBIEVDMzg0MR8wHQYJKoZIhvcNAQkBFhBpZ29yQHJ6ZWdvY2tp
        LnBsMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEVCBJ7awshmBTEiyKg5klvzYQXvXB
        6R5659lLboN5p4HKcK5RLNncgdVhFueA9Bpk4/ezhVSy3dD4amFkZ3R0IG7W0WW/
        Yut3zEQW8pFT//v/V17Miunlhjig4HLUQ8OPo2MwYTAdBgNVHQ4EFgQUdT6x/6VR
        T7N5G5emFOarZ/zjaJ0wHwYDVR0jBBgwFoAUdT6x/6VRT7N5G5emFOarZ/zjaJ0w
        DwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZIzj0EAwIDaQAw
        ZgIxALKhXmYw4HyJTGIU0wkAZUdhPF6EEpaLByhgnrf68EqAb4H8g1zi3WZ7UPBL
        lIJT/AIxAN3dzdIbYAfb9c4p7lXqBmWY9Ft7+hTwf/kJw5Br1gJc21r3sD6HAjLy
        cLErk23hVg==
        -----END CERTIFICATE-----
      ''
      # homelab fallback
      ''
        -----BEGIN CERTIFICATE-----
        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
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
      startupPage = "https://www.rzegocki.dev/";
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
      wakapi.url = "https://wakapi.ajgon.casa";
    };
    whatsapp.enable = true;
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
