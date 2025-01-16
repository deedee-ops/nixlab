{
  osConfig,
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
      (pkgs.callPackage ../../pkgs/retrom.nix { supportNvidia = osConfig.myHardware.nvidia.enable; })
    ];

    xdg.configFile."com.retrom.client/config.json".text = ''
      {
        "server": {
          "hostname": "http://${osConfig.myInfra.machines.deedee.ip}",
          "port": 5101,
          "standalone": false
        },
        "config": {
          "clientInfo": {
            "id": 1,
            "name": "nixos"
          },
          "interface": {
            "fullscreenByDefault": false
          }
        },
        "flowCompletions": {
          "setupComplete": true
        }
      }
    '';
  };
}
