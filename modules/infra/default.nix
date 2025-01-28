{ config, lib, ... }:
{
  imports = [
    ./config.nix

    ./hosts.nix
  ];

  options.myInfra = {
    cidrs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "List of CIDRs.";
      default = { };
      example = {
        trusted = "10.1.1.1/24";
        untrusted = "10.2.1.1/16";
      };
      internal = true;
    };
    devices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            ip = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Device IP";
              default = null;
            };
            mac = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Device MAC address";
              default = null;
            };
          };
        }
      );
      description = "List of IPs and MACs of client devices. Used mostly for bluetooth or static IPs.";
      default = { };
      example = {
        ps5 = {
          ip = "10.2.3.4";
          mac = "00:11:22:33:44:55";
        };
      };
      internal = true;
    };
    machines = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            ip = lib.mkOption {
              type = lib.types.str;
              description = "Machine IP";
            };
            ssh = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Machine SSH connection string";
              default = null;
            };
            host = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Machine host in local network";
            };
          };
        }
      );
      default = { };
      internal = true;
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.lists.all (device: device.ip != null || device.mac != null) (
          builtins.attrValues config.myInfra.devices
        );
        message = "Each infra device must have either IP or MAC set.";
      }
    ];
  };
}
