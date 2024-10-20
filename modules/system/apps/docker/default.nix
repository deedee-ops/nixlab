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
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of the network used by containers.";
            default = "homelab";
          };
          subnet = lib.mkOption {
            type = lib.types.str;
            description = "Subnet of the network userd by containers.";
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
        name = "homelab";
        subnet = "172.30.0.0/16";
        hostIP = "172.30.0.1";
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
        ${dockerBin} network inspect ${cfg.network.name} >/dev/null 2>&1 || ${dockerBin} network create ${cfg.network.name} --subnet ${cfg.network.subnet}
      '';
  };
}
