{ config, lib, ... }:
let
  cfg = config.myHomeApps.zathura;
in
{
  options.myHomeApps.zathura = {
    enable = lib.mkEnableOption "zathura";
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.zathura.enable = true;

    programs.zathura.enable = true;
  };
}
