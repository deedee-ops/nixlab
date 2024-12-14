{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.mail-archive;
  secretEnvs = [ "DOVECOT_PASSWD" ];
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "mail-archive-dovecot";
    };

    virtualisation.oci-containers.containers.mail-archive-dovecot = svc.mkContainer {
      cfg = {
        image = "ghcr.io/slusarz/dovecot-fts-flatcurve:v1.0.5@sha256:3a11df7028e476e2c0b971907cb48a525d37276961bcc44bfb7360f49950236c";
        volumes = [
          "${cfg.dataDir}/dovecot:/srv/mail"
          "${./dovecot.conf}:/etc/dovecot/dovecot.conf:ro"
          "${config.sops.secrets."${cfg.sopsSecretPrefix}/DOVECOT_PASSWD".path}:/etc/dovecot/passwd:ro"
        ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_FSETID"
          "--cap-add=CAP_KILL"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
          "--cap-add=CAP_SYS_CHROOT"
        ];
      };
      opts = {
        readOnlyRootFilesystem = false;
      };
    };

    systemd.services.docker-mail-archive-dovecot = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/dovecot"
        chown 1000:1000 "${cfg.dataDir}/dovecot"

        # ugly hack to fix dovecot permissions, as sops-nix doesn't allow setting direct UID/GID yet
        chown 1001:1001 "${config.sops.secrets."${cfg.sopsSecretPrefix}/DOVECOT_PASSWD".path}"
      '';
    };
  };
}
