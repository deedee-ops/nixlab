{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.mail-archive;
  secretEnvs = [
    "SOURCE_HOST"
    "SOURCE_USER"
    "SOURCE_PASS"
    "DESTINATION_USER"
    "DESTINATION_PASS"
  ];
in
{
  config = lib.mkIf (cfg.enable && !config.mySystem.recoveryMode) {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for mail-archive are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "mail-archive-imapsync";
    };

    systemd = {
      services.docker-mail-archive-imapsync = {
        description = "Sync emails";
        path = [
          pkgs.imapsync
          pkgs.dnsutils
        ];
        environment = {
          TMPDIR = "/tmp";
        };
        serviceConfig.Type = "simple";
        after = [ "docker-mail-archive-dovecot.service" ];
        requires = [ "docker-mail-archive-dovecot.service" ];
        script = ''
          DOVECOT_IP="$(${lib.getExe' pkgs.dnsutils "dig"} +short -p 5533 mail-archive-dovecot.docker @127.0.0.1)"

          ${lib.getExe pkgs.imapsync} \
          --host1 "$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/SOURCE_HOST".path})" \
          --user1 "$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/SOURCE_USER".path})" \
          --passfile1 "${config.sops.secrets."${cfg.sopsSecretPrefix}/SOURCE_PASS".path}" \
          --ssl1 \
          --host2 "$DOVECOT_IP" \
          --user2 "$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/DESTINATION_USER".path})" \
          --passfile2 "${config.sops.secrets."${cfg.sopsSecretPrefix}/DESTINATION_PASS".path}" \
          --usecache \
          --exclude 'INBOX|Sent|Drafts|Junk|Trash' \
          --nofoldersizes \
          --tmpdir "${cfg.dataDir}/imapsync" \
          --logdir "${cfg.dataDir}/imapsync" \
          --logfile log.txt \
          --pidfile "${cfg.dataDir}/imapsync/imapsync.pid"
        '';
      };

      timers.docker-mail-archive-imapsync = {
        description = "Sync emails timer.";
        wantedBy = [ "timers.target" ];
        partOf = [ "mail-archive-imapsync.service" ];
        timerConfig.OnCalendar = "hourly";
        timerConfig.Persistent = "true";
      };
    };
  };
}
