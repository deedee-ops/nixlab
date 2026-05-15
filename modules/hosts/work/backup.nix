_: {
  flake.nixosModules.hosts-work-backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      commonBackupOpts = {
        backupPrepareCommand = ''
          # remove stale locks - this avoids some occasional annoyance
          #
          ${lib.getExe pkgs.restic} unlock --remove-all || true
        '';
        initialize = true;
        paths = [
          "${config.home-manager.users."${config.features.nixos.user.name}".home.homeDirectory}/Projects"
        ];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 10"
        ];
        timerConfig = {
          OnCalendar = "Mon..Fri 09..17:00:00 ${config.features.nixos.time.timeZone}";
          Persistent = true;
        };
      };
    in
    {
      sops.secrets = {
        "features/backups/local/password" = { };
        "features/backups/repo-borgbase-eu/password" = { };
        "features/backups/repo-borgbase-eu/env" = { };
      };

      services.restic.backups = {
        projects-remote-borgbase-eu = {
          environmentFile = config.sops.secrets."features/backups/repo-borgbase-eu/env".path;
          passwordFile = config.sops.secrets."features/backups/repo-borgbase-eu/password".path;
          repository = "rest:https://ddqn91y5.repo.borgbase.com/projects";
        }
        // commonBackupOpts;
        projects-local = {
          passwordFile = config.sops.secrets."features/backups/local/password".path;
          repository = "/mnt/backup/projects";
        }
        // commonBackupOpts;
      };
    };
}
