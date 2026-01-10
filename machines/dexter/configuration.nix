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
    bluetooth = {
      enable = true;
      trust = [ config.myInfra.devices.headphones.mac ];
    };
    i915.enable = true;
    sound.enable = true;
  };

  mySystem = {
    purpose = "Main client";
    filesystem = "ext4";
    primaryUser = "ajgon";
    primaryUserExtraDirs = [
      "/mnt"
    ];
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    notificationEmail = "homelab@rzegocki.dev";
    notificationSender = "deedee@rzegocki.dev";
    powerSaveMode = false;
    powerUSBWhitelist = [
      "Bluetooth USB Adapter"
      "2.4G Receiver"
      "Security Key by Yubico"
      "USB Keyboard"
      "HD 350BT"
    ];
    trustedRootCertificates = [
      (builtins.readFile ../../assets/ca-ec384.crt)
      (builtins.readFile ../../assets/ca-rsa4096.crt)
    ];

    alerts = {
      pushover.enable = true;
    };

    disks = {
      enable = true;
      hostId = "afe7d4b1";
      swapSize = "4G";
      systemDiskDevs = [
        "/dev/disk/by-id/nvme-KINGSTON_OM8PGP41024Q-A0_50026B7382DA5EF6"
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
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "dexter";
      mainInterface = {
        name = "enp89s0";
        bridge = true;
        bridgeMAC = "02:00:c0:a8:02:c8";
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
    theme.terminalFontSize = 10;

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

    atuin = {
      enable = true;
      syncAddress = "https://atuin.ajgon.casa";
    };
    awesome.enable = true;
    caffeine.enable = true;
    discord.enable = true;
    firefox = {
      enable = true;
      startupPage = "https://www.ajgon.casa/";
    };
    freerdp = {
      enable = true;
      windowsHosts = {
        "Windows 10 RDP" = {
          inherit (config.myInfra.machines.windows) host;
          username = "ajgon";
          passwordSopsSecret = "home/apps/freerdp/windows-10";
        };
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
      features = {
        launcher = false;
        windowSwitcher = false;
        sshShell = false;
        clipboard = false;
        passwordManager = false;
        pinentry = false;
      };
    };
    rustdesk.enable = true;
    syncthing.enable = true;
    teams.enable = true;
    telegram.enable = true;
    thunderbird.enable = true;
    todoist.enable = true;
    vicinae = {
      enable = true;
      passwordManager = {
        type = "bitwarden";
        options = {
          baseUrl = "https://vault.bitwarden.eu";
        };
      };
      features = {
        todoQuickAdd = false;
      };
    };
    wakatime = {
      enable = true;
      wakapi.url = "https://wakapi.ajgon.casa";
    };
    xorg = {
      autorandr = {
        profile = {
          fingerprint = {
            "DP-1" =
              "00ffffffffffff000472b1061c118194301d0103803c22782a2711ac5135b5260e5054bfef80714f8140818081c081009500b300d1c04dd000a0f0703e803020350055502100001ab46600a0f0701f800820180455502100001a000000fd00283c1ea03c000a202020202020000000fc0058563237334b0a20202020202001e6020350f154010304121304041f100404025d5e5f606120212223090707830100006d030c002000383c20006001020367d85dc401788003681a00000101283ce6e305e301e40f008001e606070161561c023a801871382d40582c450055502100001e8c0ad08a20e02d10103e96005550210000180000000000000000000000af";
            "HDMI-1" =
              "00ffffffffffff000472830b106400000c210103803c21782a1f51ae4e33a422125054bfef80714f8140818081c09500b300d1c0d1fc4dd000a0f0703e803020350055502100001a000000ff0039333132303239413032583030000000fd0030901eff82000a202020202020000000fc0058563237354b20560a20202020026d020363f2e2780257101f0102030405060711121314151620615e5f765d603f23097f0783010000e40f0000396c030c00200038782000400102e200efe305c301e60605016262546d1a000002013090e6006a54403d6dd85dc401ffc0330a3090c1330c6a5e00a0a0a029503020350055502100001a00000000000000000000d8701267000003006448f80104ff0e4f0007801f006f087e007000070097e20004ff099f002f801f009f05280002000400d3bc0004ff099f002f801f009f05280002000400378b00047f07170157002b0037042c0003000400e51e0204ff0e81002f001f006f081b0002000400fe00000000000000000000000000000000000090";
          };
          config = {
            "DP-1" = {
              enable = true;
              crtc = 0;
              dpi = 192;
              # gamma = "1.0:0.769:0.556";
              gamma = "1.099:1.0:0.909";
              # gamma = "1.0:0.909:0.833";
              mode = "3840x2160";
              position = "0x0";
              primary = true;
              rate = "60.00";
            };
            "HDMI-1" = {
              enable = true;
              crtc = 1;
              dpi = 192;
              # gamma = "1.0:0.769:0.556";
              gamma = "1.099:1.0:0.909";
              # gamma = "1.0:0.909:0.833";
              mode = "3840x2160";
              position = "3840x0";
              rate = "60.00";
            };
          };
        };
      };
      muteSoundOnStart = true;
      terminal = pkgs.ghostty;
    };
    yt-dlp.enable = true;
    zathura.enable = true;
    zoom.enable = true;
    zsh.promptColor = "magenta";
  };

  myRetro = {
    core = {
      savesDir = "${homeDir}/Sync/retrosaves";
      screenWidth = 3840;
      screenHeight = 2160;
    };
    retrom = {
      enable = false;
      server = {
        hostname = "https://retrom-server.rzegocki.dev";
        port = 443;
      };
    };
  };

  system.stateVersion = "24.11";
}
