{ self, ... }:
{
  flake.nixosModules.hardware-ms-01 = _: {
    imports = [
      self.nixosModules.hardware-i915
    ];

    config = {
      boot = {
        initrd = {
          availableKernelModules = [
            "xhci_pci"
            "thunderbolt"
            "nvme"
            "usb_storage"
            "usbhid"
            "sd_mod"
          ];
          kernelModules = [ ];
        };
        kernelModules = [ "kvm-intel" ];
        kernelParams = [
          "intel_iommu=on"
          "iommu=pt"
        ];
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
    };
  };
}
