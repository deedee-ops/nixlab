{
  inputs,
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
    server = lib.mkOption {
      type = lib.types.submodule {
        options = {
          hostname = lib.mkOption {
            type = lib.types.str;
            description = "Hostname including proto, but without port.";
            example = "https://retrom.example.com";
          };
          port = lib.mkOption {
            type = lib.types.port;
            description = "Port number.";
            example = 443;
            default = 5101;
          };
          standalone = lib.mkOption {
            type = lib.types.bool;
            description = "Use built-in server.";
            default = false;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.callPackage ../../pkgs/retrom.nix {
        inherit (inputs) fenix;
        supportNvidia = osConfig.myHardware.nvidia.enable;
      })
    ];

    xdg.configFile."com.retrom.client/config.json".text = ''
      {
        "server": ${builtins.toJSON cfg.server},
        "config": {
          "clientInfo": {
            "id": 1,
            "name": "nixos"
          },
          "interface": {
            "fullscreenByDefault": false
          },
          "installationDir": "${config.xdg.dataHome}/retrom"
        },
        "flowCompletions": {
          "setupComplete": true
        }
      }
    '';
  };
}
