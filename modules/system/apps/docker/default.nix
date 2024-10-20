{ config, lib, ... }:
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

    users.users."${config.mySystem.primaryUser}".extraGroups = [ "docker" ];
    networking.firewall.interfaces."docker0".allowedUDPPorts = [ 53 ];
  };
}
