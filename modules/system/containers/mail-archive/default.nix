{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.mail-archive;
in
{
  imports = [
    ./dovecot.nix
    ./imapsync.nix
    ./roundcube.nix
  ];

  options.mySystemApps.mail-archive = {
    enable = lib.mkEnableOption "mail-archive container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/mail-archive";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/mail-archive/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for mail-archive are disabled!") ];

    services = {
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "mail-archive-dovecot";
          paths = [ cfg.dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps."Mail Archive" = svc.mkHomepage "mail" // {
        description = "Mail archive browser.";
        container = "mail-archive-dovecot";
        icon = "roundcube.svg";
      };
    };
  };
}
