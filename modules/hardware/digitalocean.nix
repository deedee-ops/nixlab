_: {
  flake.nixosModules.hardware-digitalocean =
    { modulesPath, lib, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      config = {
        # Workaround for https://github.com/NixOS/nix/issues/8502
        services.logrotate.checkConfig = false;

        boot = {
          tmp.cleanOnBoot = true;
          initrd = {
            availableKernelModules = [
              "ata_piix"
              "uhci_hcd"
              "vmw_pvscsi"
              "xen_blkfront"
            ];
            kernelModules = [ "nvme" ];
          };
          kernelModules = [ "kvm-intel" ];
          kernelParams = [ "nomodeset" ];
          extraModulePackages = [ ];
          loader = {
            systemd-boot.enable = false;
            grub.device = "/dev/vda";
          };
        };

        fileSystems."/" = {
          device = "/dev/vda1";
          fsType = "ext4";
        };

        # This is headless server, DBUS user sessions shouldn't be fired
        security.pam.services.sshd.startSession = lib.mkForce false;

        nixpkgs.hostPlatform = "x86_64-linux";
      };
    };
}
