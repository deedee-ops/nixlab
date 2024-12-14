{
  config,
  lib,
  svc,
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
                hostIP = lib.mkOption {
                  type = lib.types.str;
                  description = "IP under which the host is reachable for given network.";
                  default = "172.31.0.1";
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
    startDockerSockProxy = lib.mkOption {
      type = lib.types.bool;
      description = "Start read-only proxy with minimal permissions, for docker.sock, to avoid mounting it directly in containers.";
      default = false;
      example = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (!cfg.rootless) || (!cfg.startDockerSockProxy);
        message = "docker.sock proxy is currently only supported in root mode";
      }
    ];

    virtualisation = {
      oci-containers = {
        backend = "docker";
        containers.socket-proxy = lib.mkIf cfg.startDockerSockProxy (
          svc.mkContainer {
            cfg = {
              image = "ghcr.io/tecnativa/docker-socket-proxy:0.3@sha256:2f92c6e85a1199b3403c99d7439695898a162c69689b11130450ffadb352f0a0";
              environment = {
                CONTAINERS = "1";
                POST = "0";
              };
              volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ]; # in rootless mode, socket lives under /run/<user id>/....
            };
            opts = {
              readOnlyRootFilesystem = false;
            };
          }
        );
      };

      docker = {
        enable = true;
        daemon.settings = cfg.daemonSettings;
        autoPrune = {
          enable = true;
          dates = "daily";
          flags = [ "--all" ];
        };
        rootless = {
          enable = cfg.rootless;
          daemon.settings = cfg.daemonSettings;
          setSocketVariable = true;
        };
        storageDriver = lib.mkIf (config.mySystem.filesystem == "zfs") "zfs";
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

    systemd.services.docker.postStart =
      let
        dockerBin = lib.getExe pkgs."${config.virtualisation.oci-containers.backend}";
      in
      lib.mkAfter ''
        ${dockerBin} network inspect ${cfg.network.private.name} >/dev/null 2>&1 || ${dockerBin} network create ${cfg.network.private.name} --subnet ${cfg.network.private.subnet} --internal
        ${dockerBin} network inspect ${cfg.network.public.name} >/dev/null 2>&1 || ${dockerBin} network create ${cfg.network.public.name} --subnet ${cfg.network.public.subnet}
      '';

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ "/var/lib/docker" ]; };
  };
}
