{ config, lib, ... }:
let
  cfg = config.mySystemApps.redis;
in
{
  options.mySystemApps.redis = {
    enable = lib.mkEnableOption "redis";
  };

  config = lib.mkIf cfg.enable { services.redis.servers."".enable = true; };
}
