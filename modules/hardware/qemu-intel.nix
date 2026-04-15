_: {
  flake.nixosModules.hardware-qemu-intel =
    {
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      config = {
        boot = {
          extraModulePackages = [ ];
          initrd = {
            availableKernelModules = [
              "ata_piix"
              "uhci_hcd"
              "virtio_pci"
              "virtio_scsi"
              "sd_mod"
              "sr_mod"
            ];
            kernelModules = [ ];
          };
          kernelModules = [ ];
        };

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      };
    };
}
