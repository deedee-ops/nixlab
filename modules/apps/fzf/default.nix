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
    enable = lib.mkEnableEnabledOption "fzf";
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.fzf.enable = true;

    programs.fzf = {
      enable = true;
    };
  };
}
