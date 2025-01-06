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
    servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      description = "Map of server names with ports to be spawned.";
      default = { };
      example = {
        "myserver" = 6380;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.passFileSopsSecret}" = {
      group = config.users.groups.abc.name;
      mode = "0440";
      restartUnits = builtins.map (name: "redis-${name}.service") (builtins.attrNames cfg.servers);
    };

    services.redis.servers = builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = {
          enable = true;
          bind = null;
          group = config.users.groups.abc.name;
          openFirewall = true;
          port = builtins.getAttr name cfg.servers;
          requirePassFile = config.sops.secrets."${cfg.passFileSopsSecret}".path;
        };
      }) (builtins.attrNames cfg.servers)
    );

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ "/var/lib/redis" ]; };
  };
}
