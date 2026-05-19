{ self, ... }:
{
  flake.nixosModules.hosts-dexter-configuration =
    { pkgs, ... }:
    let
      trustedRootCertificates = [
        (builtins.readFile ../../../assets/ca-work.crt)
        (builtins.readFile ../../../assets/ca-ec384.crt)
        (builtins.readFile ../../../assets/ca-rsa4096.crt)
      ];

      primaryUser = "ajgon";
      qrcpPort = 55555;
      homeModules = [
        self.homeModules.features-home
        self.homeModules.features-home-console
        self.homeModules.features-home-gui

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-ms-01

        self.nixosModules.features-nixos-core
        self.nixosModules.features-nixos-desktop
        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-networking
        self.nixosModules.features-nixos-vms

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
            swapSize = "8G";
            systemDiskDevs = [ "/dev/nvme0n1" ];
          };

          docker.username = primaryUser;

          grub = {
            mode = "uefi";
            efiInstallAsRemovable = true;
          };

          home-manager = {
            username = primaryUser;
            modules = homeModules;
          };

          networking = {
            firewall = {
              enable = true;
              openPorts = [ qrcpPort ];
            };
            hostname = "dexter";
            mainInterface = {
              name = "enp89s0";
              bridge = true;
              bridgeMAC = "02:00:c0:a8:02:c8";
            };
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

          vms = {
            username = primaryUser;
            dataFS = {
              device = "/dev/nvme1n1";
              fsType = "xfs";
            };
          };
        };
      };

      home-manager.users."${primaryUser}".features.home = {
        firefox = {
          inherit trustedRootCertificates;

          features = [
            "iHD"
            "doh"
          ];
        };

        gnupg.pinentryPackage = pkgs.pinentry-qt;

        niri = {
          features = [ "iHD" ];
          displays = [
            "DP-1"
            "HDMI-A-1"
          ];
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
        };

        ssh.appendOptions = {
          settings = {
            # private
            "Host git.ajgon.casa" = {
              ForwardAgent = false;
              HostName = "git.ajgon.casa";
              IdentitiesOnly = true;
              Port = 22;
              User = "git";
            };
            mandark = {
              ForwardAgent = true;
              HostName = "relay.rzegocki.dev";
              IdentitiesOnly = true;
              Port = 22;
              User = "ajgon";
            };
            nas = {
              ForwardAgent = false;
              HostName = "nas.internal";
              IdentitiesOnly = true;
              Port = 22;
              User = "ajgon";
            };
            work = {
              ForwardAgent = false;
              HostName = "192.168.2.210";
              IdentitiesOnly = true;
              Port = 22;
              User = "ajgon";
              StrictHostKeyChecking = false;
              UserKnownHostsFile = "/dev/null";
            };

            # public
            "Host github.com" = {
              ForwardAgent = false;
              HostName = "github.com";
              IdentitiesOnly = true;
              Port = 22;
              User = "git";
            };
          };
        };

        thunderbird = {
          inherit trustedRootCertificates;
        };

        zsh.qrcp.port = qrcpPort;
      };

      system.stateVersion = "25.11";
    };
}
