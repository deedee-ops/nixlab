_: {
  flake.nixosModules.hardware-qemu-guest =
    { lib, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      config = {
        boot = {
          extraModulePackages = [ ];
          initrd = {
            availableKernelModules = [
              "ahci"
              "ata_piix"
              "sd_mod"
              "sr_mod"
              "uhci_hcd"
              "virtio_pci"
              "virtio_scsi"
            ];
            kernelModules = [ ];
          };
          kernelModules = [
            "kvm-intel"
            "kvm-amd"
          ];
          kernelParams = [ "nomodeset" ];
        };

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      };
    };
}
