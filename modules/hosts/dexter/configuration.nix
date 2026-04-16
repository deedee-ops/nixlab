{ self, ... }:
{
  flake.nixosModules.hosts-dexter-configuration =
    _:
    let
      primaryUser = "ajgonoix";
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
        self.homeModules.features-home-zsh

        self.homeModules.features-home-ghostty

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-ms-01

        self.nixosModules.features-nixos-disks
        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-home-manager
        self.nixosModules.features-nixos-locales
        self.nixosModules.features-nixos-networking
        self.nixosModules.features-nixos-ssh
        self.nixosModules.features-nixos-system
        self.nixosModules.features-nixos-time
        self.nixosModules.features-nixos-user

        self.nixosModules.features-nixos-niri

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
            swapSize = "4G";
            systemDiskDevs = [ "/dev/nvme0n1" ];
          };

          grub.mode = "uefi";

          home-manager = {
            username = "${primaryUser}";
            modules = homeModules;
          };

          networking = {
            firewallEnable = false;
            hostname = "dexter";
            mainInterface = {
              name = "enp89s0";
              bridge = true;
              bridgeMAC = "02:00:c0:a8:02:c8";
            };
          };

          niri = {
            monitors = [
              "DP-1"
              "HDMI-A-1"
            ];
            noctaliaShellExtraSettings = {
              general = {
                avatarImage = "/home/${primaryUser}/.face";
              };
              # TODO:
              wallpaper = {
                directory = "/home/${primaryUser}/Pictures/Wallpapers";
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
            trustedRootCertificates = [
              (builtins.readFile ../../../assets/ca-ec384.crt)
              (builtins.readFile ../../../assets/ca-rsa4096.crt)
            ];
          };

          user = {
            name = primaryUser;
            extraDirectories = [ "/mnt" ];
          };
        };
      };

      system.stateVersion = "25.11";
    };
}
