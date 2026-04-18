_: {
  flake.nixosModules.hardware-zenbook-14 = _: {
    config = {
      boot = {
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "usb_storage"
            "sd_mod"
            "rtsx_pci_sdmmc"
          ];
          kernelModules = [ ];
        };
        kernelModules = [
          "amdgpu"
          "kvm-amd"
        ];
        kernelParams = [
          "amd_iommu=on"
          "iommu=pt"
        ];
        extraModulePackages = [ ];
      };

      nixpkgs.hostPlatform = "x86_64-linux";

      hardware = {
        cpu.amd.updateMicrocode = true;
        enableRedistributableFirmware = true;
        usb-modeswitch.enable = true;
      };

      # power
      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        HandlePowerKey = "suspend";
        HandlePowerKeyLongPress = "poweroff";
      };
    };
  };
}
