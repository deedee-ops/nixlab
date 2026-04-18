{ self, inputs, ... }:
{
  flake.nixosModules.hosts-liadtop-configuration =
    { pkgs, ... }:
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
        self.homeModules.features-home-kitty
        self.homeModules.features-home-obsidian
        self.homeModules.features-home-syncthing
        self.homeModules.features-home-teams
        self.homeModules.features-home-telegram
        self.homeModules.features-home-thunderbird
        self.homeModules.features-home-vicinae

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-zenbook-14

        self.nixosModules.features-nixos-disks
        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-home-manager
        self.nixosModules.features-nixos-locales
        self.nixosModules.features-nixos-ssh
        self.nixosModules.features-nixos-system
        self.nixosModules.features-nixos-time
        self.nixosModules.features-nixos-user

        self.nixosModules.features-nixos-niri
        self.nixosModules.features-nixos-plymouth
        self.nixosModules.features-nixos-sddm

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

          grub.mode = "uefi";

          home-manager = {
            username = "${primaryUser}";
            modules = homeModules;
          };

          niri = {
            displays = [ "eDP-1" ];
            launcher = "vicinae";
            terminal = "kitty";

            noctalia = {
              extraSettings = {
                bar.widgets = builtins.fromJSON (builtins.readFile ./noctalia-widgets.json);
              };

              preInstalledPlugins = {
                tailscale = {
                  src = "${inputs.noctalia-plugins.outPath}/tailscale";
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
            "doh"
          ];
        };

        gnupg.pinentryPackage = pkgs.pinentry-qt;

        thunderbird = {
          inherit trustedRootCertificates;
        };
      };

      system.stateVersion = "25.11";
    };
}
