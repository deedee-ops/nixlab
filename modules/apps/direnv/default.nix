{ config
, lib
, ...
}:
let
  cfg = config.myHomeApps.direnv;
in
{
  options.myHomeApps.direnv = {
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
