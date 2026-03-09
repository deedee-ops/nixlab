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
        image = "docker.io/roundcube/roundcubemail:1.6.13-apache-nonroot@sha256:f613a14d7cf2949c8dc42a8b39d1ca7e9b6bfa7b8456709f2353e7ac19cf9f3c";
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
