{ lib, config, ... }:
{
  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  # power
  # on older nvidia drivers it never wakes up properly
  services.logind.extraConfig =
    lib.optionalString (config.hardware.nvidia.package.version >= "570")
      ''
        HandlePowerKey=suspend
        IdleAction=suspend
        IdleActionSec=5m
      '';

  myHardware = {
    openrgb = {
      enable = true;
      profile = ./openrgb/desktop.orp;
    };
  };
}
