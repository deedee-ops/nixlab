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
        image = "docker.io/roundcube/roundcubemail:1.6.11-apache-nonroot@sha256:14a7e9498d0493aef6488fa45f9cec2e3b23bae5d743ed1cd86c5a7dcb6e0e74";
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
