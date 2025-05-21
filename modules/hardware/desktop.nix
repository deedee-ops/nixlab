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
    kernelParams = [ "amd_pstate=passive" ];
    extraModulePackages = [ ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  # power
  services.logind.extraConfig =
    if (config.mySystem.powerSaveMode || !config.systemd.targets.suspend.enable) then
      ''
        HandlePowerKey=poweroff
        IdleAction=poweroff
        IdleActionSec=5m
      ''
    else
      lib.optionalString ''
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
