{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "nomodeset" ];
    extraModulePackages = [ ];
    loader.systemd-boot.enable = true;
  };

  mySystem.hardwareModule = "vm-amd";

  nixpkgs.hostPlatform = "x86_64-linux";
}
