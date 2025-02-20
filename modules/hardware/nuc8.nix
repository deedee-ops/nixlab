{ inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.intel-nuc-8i7beh
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };
}
