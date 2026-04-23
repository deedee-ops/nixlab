_: {
  flake.nixosModules.hardware-qemu-amd =
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
              "ahci"
              "uhci_hcd"
              "virtio_pci"
              "virtio_scsi"
              "sd_mod"
              "sr_mod"
            ];
            kernelModules = [ ];
          };
          kernelModules = [ "kvm-amd" ];
          kernelParams = [ "nomodeset" ];
        };

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      };
    };
}
