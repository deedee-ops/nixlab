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
        image = "ghcr.io/deedee-ops/roundcube:1.6.10@sha256:c29f47d50740e4c2c5aeb43d3b37e0ce9ac79584ddf6d4f58696d52d885dbc7d";
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
