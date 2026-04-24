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
        userMapping = lib.mkOption {
          type = lib.types.submodule {
            options = {
              host = lib.mkOption {
                type = lib.types.str;
                description = "Username used host side.";
              };
              guest = lib.mkOption {
                type = lib.types.str;
                description = "Username user VM side.";
              };
            };
          };
          example = {
            host = "userHost";
            guest = "userGuest";
          };
        };
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
          diskSize = 256000; # 250G
          graphics = false;
          memorySize = 8192;

          forwardPorts = map (mapping: {
            from = "host";
            host.port = mapping.host;
            guest.port = mapping.guest;
          }) cfg.portMappings;

          sharedDirectories = {
            downloads = {
              source = "/home/${cfg.userMapping.host}/Downloads";
              target = "/home/${cfg.userMapping.guest}/Downloads";
            };
            projects = {
              source = "/home/${cfg.userMapping.host}/Sync/vms/${config.networking.hostName}";
              target = "/home/${cfg.userMapping.guest}/Projects";
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
