{
  config,
  lib,
  ...
}:
let
  cfg = config.myApps.fzf;
in
{
  options.myApps.fzf = {
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
