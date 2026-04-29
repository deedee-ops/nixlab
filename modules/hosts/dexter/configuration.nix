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
            firewallEnable = true;
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

      system.stateVersion = "25.11";
    };
}
