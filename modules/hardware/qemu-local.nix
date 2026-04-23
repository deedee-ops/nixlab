{ inputs, ... }:
{
  flake.nixosModules.hardware-qemu-local = _: {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
    ];

    config = {
      boot.initrd.kernelModules = [
        "9p"
        "9pnet_virtio"
        "virtio_pci"
      ];

      virtualisation = {
        cores = 8;
        graphics = false;
        memorySize = 8192;

        forwardPorts = [
          {
            from = "host";
            host.port = 2222;
            guest.port = 22;
          }
        ];
        sharedDirectories = {
          projects = {
            source = "/home/ajgon/Sync/work";
            target = "/home/ajgon/Projects";
          };

          bootstrapSSH = {
            source = "/etc/ssh";
            target = "/secrets";
          };
        };
      };
    };
  };
}
