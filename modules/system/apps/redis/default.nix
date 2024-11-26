{ config, lib, ... }:
let
  cfg = config.mySystemApps.redis;
in
{
  options.mySystemApps.redis = {
    enable = lib.mkEnableOption "redis";
    passFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing master password.";
      default = "system/apps/redis/password";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.passFileSopsSecret}" = {
      owner = "redis";
      group = config.users.groups.abc.name;
      mode = "0440";
      restartUnits = [ "redis.service" ];
    };

    services.redis.servers."" = {
      enable = true;
      bind = null;
      openFirewall = true;
      requirePassFile = config.sops.secrets."${cfg.passFileSopsSecret}".path;
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ "/var/lib/redis" ]; };
  };
}
