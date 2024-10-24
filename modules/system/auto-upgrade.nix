{ lib, config, ... }:
let
  cfg = config.mySystem.autoUpgrade;
in
{
  options.mySystem.autoUpgrade = {
    enable = lib.mkEnableOption "system auto-upgrade";
    dates = lib.mkOption {
      type = lib.types.str;
      default = "Sun 06:00";
    };
  };

  config.system.autoUpgrade = lib.mkIf cfg.enable {
    enable = true;
    flake = "github:deedee-ops/nixlab";
    flags = [
      "-L" # print build logs
    ];
    inherit (cfg) dates;
  };
}
