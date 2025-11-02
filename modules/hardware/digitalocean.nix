{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
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

  nixpkgs.hostPlatform = "x86_64-linux";
}
