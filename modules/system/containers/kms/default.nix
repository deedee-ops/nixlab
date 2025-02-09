{
  lib,
  config,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.kms;
in
{
  imports = [
    ./gui.nix
    ./server.nix
  ];

  options.mySystemApps.kms = {
    enable = lib.mkEnableOption "KMS server";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/kms";
    };
    locale = lib.mkOption {
      type = lib.types.str;
      default = "en-US";
      description = "LICD locale";
    };
  };

  config = {
    services = {
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "kms";
          paths = [ cfg.dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              directory = cfg.dataDir;
              user = "abc";
              group = "abc";
              mode = "700";
            }
          ];
        };
  };
}
