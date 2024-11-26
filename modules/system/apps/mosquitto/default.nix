{ config, lib, ... }:
let
  cfg = config.mySystemApps.mosquitto;
in
{
  options.mySystemApps.mosquitto = {
    enable = lib.mkEnableOption "mosquitto";
    hashedPassFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing hashed password.";
      default = "system/apps/mosquitto/hashedPassword";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.hashedPassFileSopsSecret}" = {
      owner = "mosquitto";
      group = config.users.groups.abc.name;
      mode = "0440";
      restartUnits = [ "mosquitto.service" ];
    };

    services.mosquitto = {
      enable = true;
      # persistance for convienience on restarts
      # but not backed up, there is no data
      # that requires keeping in MQTT
      settings = {
        persistence_location = "/var/lib/mosquitto";
        max_keepalive = 300;
      };

      listeners = [
        {
          users.mq = {
            acl = [ "readwrite #" ];
            hashedPasswordFile = config.sops.secrets."${cfg.hashedPassFileSopsSecret}".path;
          };
        }
      ];
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              directory = "/var/lib/mosquitto";
              user = "mosquitto";
              group = "mosquitto";
              mode = "750";
            }
          ];
        };

    networking.firewall.allowedTCPPorts = [ 1883 ];
  };
}
