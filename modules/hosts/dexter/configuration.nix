{ self, ... }:
{
  flake.nixosModules.hosts-dexter-configuration =
    { config, ... }:
    {
      imports = [
        self.nixosModules.hardware-ms-01

        self.nixosModules.hosts-common-desktop

        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-networking
        self.nixosModules.features-nixos-vms
      ];

      features = {
        nixos = {
          disks = {
            enable = true;
            filesystem = "ext4";
            swapSize = "8G";
            systemDiskDevs = [ "/dev/disk/by-id/nvme-KINGSTON_OM8PGP41024Q-A0_50026B7382DA5EF6" ];
          };

          grub = {
            mode = "uefi";
            efiInstallAsRemovable = true;
          };

          networking = {
            firewall.enable = true;
            hostname = "dexter";
            mainInterface = {
              name = "enp89s0";
              bridge = true;
              bridgeMAC = "02:00:c0:a8:02:c8";
            };
          };

          vms = {
            username = config.features.nixos.user.name;
            dataFS = {
              device = "/dev/disk/by-id/nvme-Patriot_Scorch_M2_288E079211DE06830897";
              fsType = "xfs";
            };
          };
        };
      };

      home-manager.users.${config.features.nixos.user.name}.features.home = {
        niri.displays = [
          "DP-1"
          "HDMI-A-1"
        ];

        noctalia-shell.extraSettings = builtins.fromTOML (builtins.readFile ./noctalia.toml);
      };

      system.stateVersion = "25.11";
    };
}
