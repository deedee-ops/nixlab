{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.docker;
in
{
  options.mySystemApps.docker = {
    enable = lib.mkEnableOption "docker app";
    daemonSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings for docker daemon";
    };
    rootless = lib.mkEnableOption "rootless docker" // {
      default = true;
    };
    network = lib.mkOption {
      type = lib.types.submodule {
        options = {
          private = lib.mkOption {
            type = lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of the private (no internet) network used by containers.";
                  default = "private";
                };
                subnet = lib.mkOption {
                  type = lib.types.str;
                  description = "Subnet of the private (no internet) network user by containers.";
                  default = "172.30.0.0/16";
                };
                hostIP = lib.mkOption {
                  type = lib.types.str;
                  description = "IP under which the host is reachable for given network.";
                  default = "172.30.0.1";
                };
              };
            };
            default = {
              name = "private";
              subnet = "172.30.0.0/16";
              hostIP = "172.30.0.1";
            };
          };
          public = lib.mkOption {
            type = lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of the public (with internet) network used by containers.";
                  default = "public";
                };
                subnet = lib.mkOption {
                  type = lib.types.str;
                  description = "Subnet of the public (with internet) network user by containers.";
                  default = "172.31.0.0/16";
                };
              };
            };
            default = {
              name = "public";
              subnet = "172.31.0.0/16";
            };
          };
        };
      };
      default = {
        private = {
          name = "private";
          subnet = "172.30.0.0/16";
          hostIP = "172.30.0.1";
        };
        public = {
          name = "public";
          subnet = "172.31.0.0/16";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      oci-containers.backend = "docker";

      docker = {
        enable = true;
        daemon.settings = cfg.daemonSettings;
        rootless = {
          enable = cfg.rootless;
          daemon.settings = cfg.daemonSettings;
          setSocketVariable = true;
        };
      };
    };

    # default user for containers, eases secret mappings
    users = {
      users.abc = {
        isSystemUser = true;
        uid = 65000;
        group = "abc";
      };
      groups.abc.gid = 65000;
    };

    users.users."${config.mySystem.primaryUser}".extraGroups = [ "docker" ];
    networking.firewall.interfaces."docker0".allowedUDPPorts = [ 53 ];

    system.activationScripts.mkDockerNetwork =
      let
        dockerBin = lib.getExe pkgs."${config.virtualisation.oci-containers.backend}";
      in
      ''
        ${dockerBin} network inspect ${cfg.network.private.name} >/dev/null 2>&1 || ${dockerBin} network create ${cfg.network.private.name} --subnet ${cfg.network.private.subnet} --internal
        ${dockerBin} network inspect ${cfg.network.public.name} >/dev/null 2>&1 || ${dockerBin} network create ${cfg.network.public.name} --subnet ${cfg.network.public.subnet}
      '';
  };
}
