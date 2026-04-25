{ self, ... }:
{
  flake.nixosModules.hosts-liadtop-configuration =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      trustedRootCertificates = [
        (builtins.readFile ../../../assets/ca-ec384.crt)
        (builtins.readFile ../../../assets/ca-rsa4096.crt)
      ];

      primaryUser = "ajgon";
      homeModules = [
        self.homeModules.features-home
        self.homeModules.features-home-atuin
        self.homeModules.features-home-bat
        self.homeModules.features-home-btop
        self.homeModules.features-home-direnv
        self.homeModules.features-home-git
        self.homeModules.features-home-gnupg
        self.homeModules.features-home-kubernetes
        self.homeModules.features-home-neovim
        self.homeModules.features-home-ssh
        self.homeModules.features-home-wakatime
        self.homeModules.features-home-yazi
        self.homeModules.features-home-zsh

        self.homeModules.features-home-discord
        self.homeModules.features-home-firefox
        self.homeModules.features-home-keepassxc
        self.homeModules.features-home-kitty
        self.homeModules.features-home-niri
        self.homeModules.features-home-noctalia-shell
        self.homeModules.features-home-obsidian
        self.homeModules.features-home-rustdesk
        self.homeModules.features-home-supersonic
        self.homeModules.features-home-syncthing
        self.homeModules.features-home-teams
        self.homeModules.features-home-telegram
        self.homeModules.features-home-thunderbird
        self.homeModules.features-home-vicinae
        self.homeModules.features-home-zathura

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-zenbook-14

        self.nixosModules.features-nixos-disks
        self.nixosModules.features-nixos-docker
        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-home-manager
        self.nixosModules.features-nixos-locales
        self.nixosModules.features-nixos-ssh
        self.nixosModules.features-nixos-system
        self.nixosModules.features-nixos-time
        self.nixosModules.features-nixos-user

        self.nixosModules.features-nixos-plymouth
        self.nixosModules.features-nixos-sddm
        self.nixosModules.features-nixos-wayland

        self.nixosModules.theme
      ];

      sops = {
        defaultSopsFile = ./secrets.sops.yaml;
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };

      features = {
        nixos = {
          disks = {
            enable = true;
            filesystem = "ext4";
            swapSize = "24G";
            systemDiskDevs = [ "/dev/nvme0n1" ];
          };

          docker.username = primaryUser;

          grub.mode = "uefi";

          home-manager = {
            username = primaryUser;
            modules = homeModules;
          };

          ssh = {
            authorizedKeys = {
              "${primaryUser}" = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrBLT88ZZ+lO8hHcj+4jqtor79OLhQZcDWF98kkWkfn personal"
              ];
            };
          };

          system = {
            inherit trustedRootCertificates;
          };

          user = {
            name = primaryUser;
            extraDirectories = [ "/mnt" ];
          };
        };
      };

      home-manager.users."${primaryUser}" = {
        # zenbook doesn't support deep sleep so we need subpar workaround,
        # at least to turn off display
        systemd.user.services.niri-pre-sleep = {
          Unit = {
            Description = "Turn off niri displays before sleep";
            Before = "sleep.target";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe config.programs.niri.package} msg action power-off-monitors";
          };
          Install = {
            WantedBy = [ "sleep.target" ];
          };
        };

        features.home = {
          firefox = {
            inherit trustedRootCertificates;

            features = [
              "radeon"
              "doh"
            ];
          };

          gnupg.pinentryPackage = pkgs.pinentry-qt;

          niri = {
            displays = [ "eDP-1" ];
            features = [ "radeon" ];
            launcher = "vicinae";
            terminal = "kitty";
          };

          noctalia-shell = {
            extraSettings = {
              bar.widgets = builtins.fromJSON (builtins.readFile ./noctalia-bar-widgets.json);
              desktopWidgets.monitorWidgets = builtins.fromJSON (
                builtins.readFile ./noctalia-monitor-widgets.json
              );
            };
            plugins = {
              tailscale = {
                sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                settings = {
                  refreshInterval = 5000;
                  compactMode = false;
                  showIpAddress = true;
                  showPeerCount = true;
                  hideDisconnected = false;
                  hideMullvadExitNodes = true;
                  terminalCommand = "";
                  sshUsername = "";
                  pingCount = 5;
                  defaultPeerAction = "copy-ip";
                  taildropEnabled = false;
                  taildropDownloadDir = "~/Downloads";
                  taildropReceiveMode = "operator";
                  loginServer = "https://relay.rzegocki.dev";
                };
              };
            };
          };

          ssh.appendOptions = {
            matchBlocks = {
              # private
              forgejo = {
                forwardAgent = false;
                host = "git.ajgon.casa";
                hostname = "git.ajgon.casa";
                identitiesOnly = true;
                port = 22;
                user = "git";
              };
              mandark = {
                forwardAgent = true;
                host = "mandark";
                hostname = "relay.rzegocki.dev";
                identitiesOnly = true;
                port = 22;
                user = "ajgon";
              };
              nas = {
                forwardAgent = false;
                host = "nas";
                hostname = "nas.internal";
                identitiesOnly = true;
                port = 22;
                user = "ajgon";
              };
              work = {
                forwardAgent = false;
                host = "work";
                hostname = "127.0.0.1";
                identitiesOnly = true;
                port = 2222;
                user = "ajgon";
                userKnownHostsFile = "/dev/null";

                extraOptions.StrictHostKeyChecking = "no";
              };

              # public
              github = {
                forwardAgent = false;
                host = "github.com";
                hostname = "github.com";
                identitiesOnly = true;
                port = 22;
                user = "git";
              };
            };
          };

          thunderbird = {
            inherit trustedRootCertificates;
          };
        };
      };

      system.stateVersion = "25.11";
    };
}
