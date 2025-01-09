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
        image = "ghcr.io/deedee-ops/roundcube:1.6.9@sha256:647df66417b3a5fc8358dc5a633e871c8b8dfaa273723dda21e0ad83daa4bb0b";
        volumes = [ "${cfg.dataDir}/roundcube:/config" ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/app/installer,tmpfs-mode=1777"
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
          "--mount"
          "type=tmpfs,destination=/var/tmp,tmpfs-mode=1777"
        ];
      };
    };

    services = {
      nginx.virtualHosts.roundcube = svc.mkNginxVHost {
        host = "mail";
        proxyPass = "http://roundcube.docker:3000";
      };
    };

    systemd.services.docker-roundcube = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/roundcube"
        chown 65000:65000 "${cfg.dataDir}/roundcube"
      '';
    };
  };
}
