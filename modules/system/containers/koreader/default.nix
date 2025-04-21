{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.koreader;
in
{
  imports = [
    ./insight.nix
    ./sync.nix
  ];

  options.mySystemApps.koreader = {
    enable = lib.mkEnableOption "koreader containers";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/koreader";
    };
  };
  config = {
    services = {
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "koreader";
          paths = [ cfg.dataDir ];
        }
      );
    };
  };
}
