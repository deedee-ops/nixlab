{ config
, lib
, ...
}:
let
  cfg = config.myApps.direnv;
in
{
  options.myApps.direnv = {
    enable = lib.mkEnableEnabledOption "direnv";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
