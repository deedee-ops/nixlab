{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.rustdesk;
in
{
  options.myHomeApps.rustdesk = {
    enable = lib.mkEnableOption "rustdesk";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.rustdesk
      ];
    };

    myHomeApps.allowUnfree = [ "libsciter" ];
  };
}
