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
    i915.enable = true;
    sound.enable = true;
  };

  mySystem = {
    purpose = "Main client";
    filesystem = "zfs";
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

    alerts = {
      pushover.enable = true;
    };

    disks = {
      enable = true;
      hostId = "afe7d4b1";
      swapSize = "4G";
      systemDiskDevs = [
        "/dev/disk/by-id/nvme-Patriot_Scorch_M2_288E079211DE06830897"
      ];
    };

    grub = {
      enable = true;
      efiInstallAsRemovable = true;
    };

    impermanence = {
      enable = true;
      machineId = "d394e4ebdac219e695b148e395a72f3a";
      persistPath = "/persist";
      zfsPool = "rpool";
    };

    mounts = [
      {
        type = "nfs";
        src = "${config.myInfra.machines.deedee.ip}:/tank/backups";
        dest = "/tank/backups";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.deedee.ip}:/tank/data";
        dest = "/tank/data";
      }
      {
        type = "nfs";
        src = "${config.myInfra.machines.deedee.ip}:/tank/media";
        dest = "/tank/media";
        opts = "ro";
      }
    ];

    networking = {
      enable = true;
      firewallEnable = true;
      completelyDisableIPV6 = true;
      hostname = "dexter";
      nextdnsID = "1ff226";
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
    customURLs = {
      "Income Invoices" = "https://n8n.rzegocki.dev/form/bc1561cd-5b46-41cd-942c-5d0693c27d4e";
    };
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
    };
    freerdp = {
      enable = true;
      windowsHosts = {
        "Windows 10 RDP" = {
          host = config.myInfra.machines.windows.ip;
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
      passwordManager = "bitwarden";
      bitwarden = {
        email = "igor@rzegocki.pl";
        base_url = "https://vault.bitwarden.eu/";
      };
    };
    rustdesk.enable = true;
    syncthing.enable = true;
    teams.enable = true;
    telegram.enable = true;
    thunderbird.enable = true;
    todoist.enable = true;
    wakatime = {
      enable = true;
      wakapi.url = "https://wakapi.rzegocki.dev";
    };
    whatsapp.enable = true;
    xorg = {
      autorandr = {
        profile = {
          fingerprint = {
            "HDMI-1" =
              "00ffffffffffff000472b1061c118194301d0103803c22782a2711ac5135b5260e5054bfef80714f8140818081c081009500b300d1c04dd000a0f0703e803020350055502100001ab46600a0f0701f800820180455502100001a000000fd00283c1ea03c000a202020202020000000fc0058563237334b0a20202020202001e6020350f154010304121305141f100706025d5e5f606120212223090707830100006d030c002000383c20006001020367d85dc401788003681a00000101283ce6e305e301e40f008001e606070161561c023a801871382d40582c450055502100001e8c0ad08a20e02d10103e9600555021000018000000000000000000000099";
            "HDMI-2" =
              "00ffffffffffff000472830b106400000c210103803c21782a1f51ae4e33a422125054bfef80714f8140818081c09500b300d1c0d1fc4dd000a0f0703e803020350055502100001a000000ff0039333132303239413032583030000000fd0030901eff82000a202020202020000000fc0058563237354b20560a20202020026d020363f2e2780257101f0102030405060711121314151620615e5f765d603f23097f0783010000e40f0000396c030c00200038782000400102e200efe305c301e60605016262546d1a000002013090e6006a54403d6dd85dc401ffc0330a3090c1330c6a5e00a0a0a029503020350055502100001a00000000000000000000d8701267000003006448f80104ff0e4f0007801f006f087e007000070097e20004ff099f002f801f009f05280002000400d3bc0004ff099f002f801f009f05280002000400378b00047f07170157002b0037042c0003000400e51e0204ff0e81002f001f006f081b0002000400fe00000000000000000000000000000000000090";
          };
          config = {
            "HDMI-1" = {
              enable = true;
              crtc = 0;
              dpi = 192;
              gamma = "1.099:1.0:0.909";
              # gamma = "1.0:0.909:0.833";
              mode = "3840x2160";
              position = "0x0";
              primary = true;
              rate = "60.00";
            };
            "HDMI-2" = {
              crtc = 1;
              dpi = 192;
              enable = true;
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
      enable = true;
      server = {
        hostname = "https://retrom-server.rzegocki.dev";
        port = 443;
      };
    };
  };

  system.stateVersion = "24.11";
}
