{ inputs, ... }:
{
  flake.nixosModules.hardware-qemu-local =
    { config, lib, ... }:
    let
      cfg = config.features.nixos.qemu-local;
    in
    {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
      ];

      options.features.nixos.qemu-local = {
        portMappings = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                host = lib.mkOption {
                  type = lib.types.port;
                  description = "Port exposed host side.";
                };
                guest = lib.mkOption {
                  type = lib.types.port;
                  description = "Port addressed to VM side.";
                };
              };
            }
          );
          default = [ ];
          example = [
            {
              host = 2222;
              guest = 22;
            }
          ];
        };
      };

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

          forwardPorts = map (mapping: {
            from = "host";
            host.port = mapping.host;
            guest.port = mapping.guest;
          }) cfg.portMappings;

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
