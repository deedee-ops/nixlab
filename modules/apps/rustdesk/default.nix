{
  config,
  pkgs-master,
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
        # unstable build is broken atm: https://github.com/NixOS/nixpkgs/issues/475861
        pkgs-master.rustdesk-flutter
      ];
    };

    myHomeApps.allowUnfree = [ "libsciter" ];
  };
}
