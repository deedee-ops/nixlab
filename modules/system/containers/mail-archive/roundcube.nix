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
        image = "ghcr.io/deedee-ops/roundcube:1.6.10@sha256:e932fb8955023c3ed71b259537be0d22a55443b3ef783b1cc4bfd4c3b66e24b6";
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
