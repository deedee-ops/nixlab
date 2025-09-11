{ config, lib, ... }:
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
    kernelParams = [
      "amd_pstate=passive"
      "microcode.amd_sha_check=off"
    ]
    ++ lib.optionals config.mySystem.vmPassthrough [
      "amd_iommu=on"
      "iommu=pt"
    ];
    extraModulePackages = [ ];
  }
  // lib.optionalAttrs config.mySystem.vmPassthrough {
    extraModprobeConfig = "options vfio-pci ids=10de:1c82,10de:0fb9"; # 1050 Ti
    # extraModprobeConfig = "options vfio-pci ids=10de:2482,10de:228b";  # 3070 Ti
    postBootCommands = ''
      DEVS="0000:05:00.0 0000:05:00.1"  # 1050 Ti
      # DEVS="0000:0a:00.0 0000:0a:00.1"  # 3070 Ti

      for DEV in $DEVS; do
        echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
      done
      modprobe -i vfio-pci
    '';
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  services.ucodenix = {
    enable = true;
    cpuModelId = "00870F10";
  };

  myHardware = {
    openrgb = {
      enable = true;
      profile = ./openrgb/desktop.orp;
    };
  };
}
