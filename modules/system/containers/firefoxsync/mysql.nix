{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.firefoxsync;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      firefoxsync-mysql = svc.mkContainer {
        cfg = {
          image = "docker.io/library/mariadb:lts@sha256:2bcbaec92bd9d4f6591bc8103d3a8e6d0512ee2235506e47a2e129d190444405";
          environment = {
            MARIADB_AUTO_UPGRADE = "true";
          };
          environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
          volumes = [ "${cfg.dataDir}:/var/lib/mysql" ];
          cmd = [
            "mariadbd"
            "--explicit_defaults_for_timestamp"
          ];
          extraOptions = [
            "--cap-add=CAP_CHOWN"
            "--cap-add=CAP_DAC_OVERRIDE"
            "--cap-add=CAP_FSETID"
            "--cap-add=CAP_SETGID"
            "--cap-add=CAP_SETUID"
            "--health-cmd"
            "healthcheck.sh --connect --innodb_initialized"
            "--health-start-period=10s"
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-retries=3"
            "--mount"
            "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
            "--mount"
            "type=tmpfs,destination=/run/mysqld,tmpfs-mode=1777"
          ];
        };
      };
    };

    systemd.services =
      let
        dockerBin = lib.getExe pkgs."${config.virtualisation.oci-containers.backend}";
      in
      {
        docker-firefoxsync = {
          postStart = lib.mkAfter ''
            until ${dockerBin} ps | grep firefoxsync-mysql | grep -q healthy; do sleep 1; done
            ${dockerBin} run --rm \
            -e DOMAIN=https://firefoxsync.${config.mySystem.rootDomain} \
            -e MARIADB_SERVER=firefoxsync-mysql \
            -e MARIADB_SERVER_PORT=3306 \
            -e MAX_USERS=1 \
            --env-file=${config.sops.secrets."${cfg.envFileSopsSecret}".path} \
            --entrypoint=/db_init.sh \
            --network=private \
            ghcr.io/porelli/firefox-sync:syncstorage-rs-mysql-init-latest
          '';
        };
        docker-firefoxsync-mysql = {
          postStart = lib.mkAfter ''
            until ${dockerBin} ps | grep firefoxsync-mysql | grep -q healthy; do sleep 1; done
            ${dockerBin} run --rm \
            --env-file=${config.sops.secrets."${cfg.envFileSopsSecret}".path} \
            --network=private \
            docker.io/library/mariadb:lts \
            sh -c 'mariadb -u root -p$MARIADB_ROOT_PASSWORD -h firefoxsync-mysql -e "CREATE DATABASE IF NOT EXISTS $MARIADB_SYNC_DATABASE; GRANT ALL PRIVILEGES ON $MARIADB_SYNC_DATABASE.* TO '"'"'$MARIADB_USER'"'"'@'"'"'%'"'"' WITH GRANT OPTION;"'
          '';
        };
      };
  };
}
