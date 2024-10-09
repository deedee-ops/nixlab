{ config
, lib
, ...
}:
let
  cfg = config.myApps.direnv;
in
{
  options.myApps.direnv = {
    enable = lib.mkEnableOption "direnv" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
