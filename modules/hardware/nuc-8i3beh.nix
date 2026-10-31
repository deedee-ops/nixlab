{ self, ... }:
{
  # Intel NUC8i3BEH (Bean Canyon): i3-8109U, Iris Plus 655, I219-V, Wireless-AC 9560, NVMe + SATA, SD card reader
  flake.nixosModules.hardware-nuc-8i3beh = _: {
    imports = [
      self.nixosModules.hardware-i915
    ];

    config = {
      boot = {
        initrd = {
          availableKernelModules = [
            "xhci_pci"
            "ahci"
            "nvme"
            "usb_storage"
            "usbhid"
            "sd_mod"
            "sdhci_pci"
          ];
          kernelModules = [ ];
        };
        kernelModules = [ "kvm-intel" ];
        kernelParams = [
          # load HuC firmware for hardware video encoding (Coffee Lake doesn't need GuC submission)
          "i915.enable_guc=2"
        ];
        extraModulePackages = [ ];
      };

      nixpkgs.hostPlatform = "x86_64-linux";

      hardware = {
        cpu.intel.updateMicrocode = true;
        # iwlwifi and bluetooth firmware for AC 9560
        enableRedistributableFirmware = true;
      };

      services = {
        fstrim.enable = true;
        # mobile CPU in a small chassis, prevents thermal throttling spikes
        thermald.enable = true;
      };
    };
  };
}
