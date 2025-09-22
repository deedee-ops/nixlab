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
        image = "docker.io/roundcube/roundcubemail:1.6.11-apache-nonroot@sha256:1d7fc1f60ae60c66c0da74c1594be030c99b564fa9db1e9f247fa9b00cfdefff";
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
