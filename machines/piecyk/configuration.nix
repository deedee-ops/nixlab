{
  config,
  pkgs,
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
    bluetooth = {
      enable = true;
      trust = [ config.myInfra.devices.headphones.mac ];
    };
    sound.enable = true;

    nvidia = {
      enable = true;
      metamodes = "DP-2: 3840x2160_120 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DP-0: 3840x2160_120 +3840+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, AllowGSYNCCompatible=On}";
    };
  };

  mySystem = {
    purpose = "Main rig";
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
      hostId = "bdd71660";
      swapSize = "4G";
      systemDiskDevs = [
        "/dev/disk/by-id/nvme-Patriot_P300_1TB_AA000000000000000047"
        "/dev/disk/by-id/nvme-KINGSTON_SA2000M81000G_50026B7683D02486"
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
      machineId = "cce12d4d401949f79845a5bce9e78e88";
      persistPath = "/persist";
      zfsPool = "rpool";
    };

    networking = {
      enable = true;
      firewallEnable = true;
      hostname = "piecyk";
      mainInterface = {
        name = "enp6s0";
        bridge = true;
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
      backupverify.enable = true;
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
          consumeDir = "${homeDir}/Sync/paperless-consume";
        };
        ssh = {
          enable = true;
          host = "nas";
          targetDir = "/volume1/private/Memories/Private/Firma/%Y/%m/koszty";
        };
      };
      pdfhelpers.enable = true;
    };

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

    atuin = {
      enable = true;
      syncAddress = "https://atuin.rzegocki.dev";
    };
    awesome.enable = true;
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
    rustdesk.enable = true;
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
    workrave.enable = true;
    xorg = {
      autorandr = {
        profile = {
          fingerprint = {
            "DP-2" =
              "00ffffffffffff000472b1061c118194301d0104b53c22783b2711ac5135b5260e50542348008140818081c081009500b300d1c001014dd000a0f0703e803020350055502100001ab46600a0f0701f800820180455502100001a000000fd0c3090ffff6b010a202020202020000000fc0058563237334b0a2020202020200247020343f151010304121305141f9007025d5e5f60613f2309070783010000e200c06d030c0010003878200060010203681a00000101309000e305e301e606070161561c0782805470384d400820f80c56502100001a40e7006aa0a06a500820980455502100001a6fc200a0a0a055503020350055502100001e0000000000007870127900000301289aa00184ff0ea0002f8021006f083e0003000500e0f600047f0759002f801f006f081900010003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003590";
            "DP-0" =
              "00ffffffffffff000472830b000000000c210104b53c21783b1f51ae4e33a422125054bfef80714f8140818081c09500b300d1c0d1fc4dd000a0f0703e803020350055502100001a000000ff0039333132303239413032583030000000fd0030a0ffff82010a202020202020000000fc0058563237354b20560a2020202002a8020345f2555d5e5f6061014003111213040e0f1d1e1f903f75762309070783010000e305c301e20f18e30e7576e200d5e60605016969006d1a0000020130a00000695500006a5e00a0a0a029503020350055502100001e000000000000000000000000000000000000000000000000000000000000000000000000000000007970126700000300648cee0104ff0e9f002f001f006f082500020004001f9c0104ff0e9f002f001f006f08250002000400e51e0204ff0e81002f001f006f081b0002000400d3bc0004ff099f002f001f009f05280002000400378b00047f07170157002b0037042c00030004007e00000000000000000000000000000000000090";
          };
          config = {
            "DP-2" = {
              crtc = 0;
              dpi = 192;
              enable = true;
              gamma = "1.099:1.0:0.909";
              mode = "3840x2160";
              position = "0x0";
              primary = true;
              rate = "119.91";
            };
            "DP-0" = {
              crtc = 1;
              dpi = 192;
              enable = true;
              gamma = "1.099:1.0:0.909";
              mode = "3840x2160";
              position = "3840x0";
              rate = "120.00";
            };
          };
        };
      };
      terminal = pkgs.kitty;
    };
    zathura.enable = true;
    zsh.promptColor = "magenta";
  };

  myRetro = {
    core = {
      savesDir = "${homeDir}/Sync/retrosaves";
      screenWidth = 3840;
      screenHeight = 2160;
    };
    retrom.enable = true;
  };

  system.stateVersion = "24.11";
}
