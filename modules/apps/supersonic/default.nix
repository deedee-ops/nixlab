{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.supersonic;
in
{
  options.myHomeApps.supersonic = {
    enable = lib.mkEnableOption "supersonic";
    package = lib.mkPackageOption pkgs "supersonic" { };
    subsonicServer = lib.mkOption {
      type = lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = "Subsonic host, without protocol.";
            example = "navidrome.example.com";
          };
          username = lib.mkOption {
            type = lib.types.str;
            description = "Subsonic username.";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.myHomeApps.xorg.enableGnomeKeyring;
        message = "myHomeApps.xorg.enableGnomeKeyring must be enabled for supersonic";
      }
    ];

    home.packages = [ pkgs.supersonic ];

    xdg.configFile =
      let
        configBase = builtins.fromTOML (builtins.readFile ./config.toml);
      in
      {
        "supersonic/config.toml".source = (pkgs.formats.toml { }).generate "config.yaml" (
          lib.recursiveUpdate configBase {
            Application = {
              LastCheckedVersion = "v${cfg.package.version}";
              LastLaunchedVersion = "v${cfg.package.version}";
            };
            Servers = [
              (
                (builtins.elemAt configBase.Servers 0)
                // {
                  Hostname = "https://${cfg.subsonicServer.host}";
                  Username = cfg.subsonicServer.username;
                }
              )
            ];
          }
        );
        "supersonic/themes/catppuccin-mocha-blue.toml".source = ./catppuccin-mocha-blue.toml;
      };
  };
}
