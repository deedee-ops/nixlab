{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myRetro.retrom;
in
{
  options.myRetro.retrom = {
    enable = lib.mkEnableOption "retrom";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.callPackage ../../pkgs/retrom.nix { })
    ];
  };
}
