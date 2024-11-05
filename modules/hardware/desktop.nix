_: {
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

  myHardware = {
    bluetooth.enable = true;
    sound.enable = true;

    nvidia = {
      enable = true;
      metamodes = "DP-2: 3840x2160_120 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DP-0: 3840x2160_120 +3840+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, AllowGSYNCCompatible=On}";
    };
  };
}
