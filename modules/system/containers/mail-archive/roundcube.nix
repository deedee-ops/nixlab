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
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.roundcube = svc.mkContainer {
      cfg = {
        image = "docker.io/roundcube/roundcubemail:1.6.11-apache-nonroot@sha256:5603849211cbf271d132b0b56f9a6db3e278a6e2531419c722f1cf1eb5a0d74d";
        environment = {
          ROUNDCUBEMAIL_DB_TYPE = "sqlite";
          ROUNDCUBEMAIL_DEFAULT_HOST = "mail-archive-dovecot";
          ROUNDCUBEMAIL_DEFAULT_PORT = "143";
          ROUNDCUBEMAIL_PLUGINS = "hide_blockquote,identicon,zipdownload";
        };
        volumes = [
          "${cfg.dataDir}/roundcube:/var/roundcube/db"
        ];
      };
      opts = {
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.roundcube = svc.mkNginxVHost {
        host = "mail";
        proxyPass = "http://roundcube.docker:8000";
      };
    };

    systemd.services.docker-roundcube = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/roundcube"
        chown 33:33 "${cfg.dataDir}/roundcube"
      '';
    };
  };
}
