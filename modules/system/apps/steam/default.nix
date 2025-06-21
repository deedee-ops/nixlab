{ config, lib, ... }:
let
  cfg = config.mySystemApps.steam;
in
{
  options.mySystemApps.steam = {
    enable = lib.mkEnableOption "steam app";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
    };

    mySystem.allowUnfree = [
      "steam"
      "steam-unwrapped"
    ];
  };
}
