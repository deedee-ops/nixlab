{
  config,
  lib,
  ...
}:
let
  cfg = config.mySystem.zfs;
in
{
  options.mySystem.zfs = {
    snapshots = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            hourly = lib.mkOption {
              type = lib.types.int;
              default = 12;
            };
            daily = lib.mkOption {
              type = lib.types.int;
              default = 7;
            };
            monthly = lib.mkOption {
              type = lib.types.int;
              default = 12;
            };
            yearly = lib.mkOption {
              type = lib.types.int;
              default = 10;
            };
          };
        }
      );
      default = { };
    };
  };

  config = lib.mkIf (config.mySystem.filesystem == "zfs") {
    services = {
      sanoid = {
        enable = true;
        interval = "hourly";
        datasets = builtins.listToAttrs (
          builtins.map (dataset: {
            name = dataset;
            value = (builtins.getAttr dataset cfg.snapshots) // {
              autoprune = true;
              autosnap = true;
            };
          }) (builtins.attrNames cfg.snapshots)
        );
      };
      zfs = {
        autoScrub.enable = true;
        trim.enable = true;
        zed.settings = lib.mkIf config.mySystem.alerts.pushover.enable {
          ZED_PUSHOVER_TOKEN = "$(source ${config.mySystem.alerts.pushover.envFileSopsSecret} && echo $PUSHOVER_API_KEY)";
          ZED_PUSHOVER_USER = "$(source ${config.mySystem.alerts.pushover.envFileSopsSecret} && echo $PUSHOVER_USER_KEY)";
        };
      };
    };
  };
}
