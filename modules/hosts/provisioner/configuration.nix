{ self, ... }:
{
  flake.nixosModules.hosts-provisioner-configuration =
    _:
    let
      primaryUser = "ajgon";
    in
    {
      imports = [
        self.nixosModules.hardware-qemu-intel
        self.nixosModules.features-nixos-disks
        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-locales
        self.nixosModules.features-nixos-networking
        self.nixosModules.features-nixos-ssh
        self.nixosModules.features-nixos-time
        self.nixosModules.features-nixos-user
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
            systemDiskDevs = [ "/dev/sda" ];
          };

          grub.mode = "legacy";

          networking = {
            firewallEnable = false;
            hostname = "provisioner";
            mainInterface.name = "ens18";
          };

          ssh = {
            authorizedKeys = {
              "${primaryUser}" = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrBLT88ZZ+lO8hHcj+4jqtor79OLhQZcDWF98kkWkfn personal"
              ];
            };
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
