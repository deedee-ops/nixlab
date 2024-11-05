{
  config,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.fzf;
in
{
  options.myHomeApps.fzf = {
    enable = lib.mkEnableOption "fzf" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.fzf.enable = true;

    programs.fzf = {
      enable = true;
    };
  };
}
