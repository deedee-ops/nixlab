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
        image = "ghcr.io/deedee-ops/roundcube:1.6.9@sha256:54baeca36c231a86eee1c81457cb655523f302d7a3258ea2dc3739942fb1d487";
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
