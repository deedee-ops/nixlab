{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.plymouth;
in
{
  options.mySystemApps.plymouth = {
    enable = lib.mkEnableOption "plymouth";
  };

  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
      theme = "catppuccin-mocha";
    };
  };
}
