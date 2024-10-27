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
        image = "ghcr.io/deedee-ops/roundcube:1.6.9@sha256:8921131e646d2bd86a22a22311747c63b2cd6f770fcc2a86bf63a1c308b9e763";
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
