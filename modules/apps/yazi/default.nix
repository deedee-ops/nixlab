{
  config,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.yazi;
in
{
  options.myHomeApps.yazi = {
    enable = lib.mkEnableOption "yazi" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.yazi.enable = true;

    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
