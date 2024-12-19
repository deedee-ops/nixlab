{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.davis;
in
{
  options.mySystemApps.davis = {
    enable = lib.mkEnableOption "davis container";
    caldavEnable = lib.mkEnableOption "CalDAV" // {
      default = true;
    };
    carddavEnable = lib.mkEnableOption "CardDAV" // {
      default = true;
    };
    webdavEnable = lib.mkEnableOption "WebDAV";
    useAuthelia = lib.mkEnableOption "authelia";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/davis";
    };
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing redlib envs.";
      default = "system/apps/davis/envfile";
    };
  };

  config =
    let
      image = "ghcr.io/tchapi/davis:5.0.2@sha256:02f9abdbd4f921b9a3ae27ff2df63ab171bbc27d01fb3ab7eb592ead367f8e06";
    in
    lib.mkIf cfg.enable {
      warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for davis are disabled!") ];

      sops.secrets."${cfg.envFileSopsSecret}" = { };

      mySystemApps.caddy = {
        enable = true;
        dependsOn = [ "davis" ];
        vhosts."davis.${config.mySystem.rootDomain}" = ''
          log
          header -Server
          header -X-Powered-By
          redir /.well-known/carddav /dav/ 301
          redir /.well-known/caldav /dav/ 301
          root * /var/www/davis/public
          encode zstd gzip
          php_fastcgi davis:9000 {
            trusted_proxies 172.16.0.0/12
          }
          file_server {
            hide .git .gitignore
          }
        '';
        mounts = [ "/var/cache/davis/web/public:/var/www/davis/public" ];
      };

      virtualisation.oci-containers.containers.davis = svc.mkContainer {
        cfg = {
          inherit image;

          user = "82:82";
          dependsOn = [ "lldap" ];
          environment = {
            ADMIN_AUTH_BYPASS = if cfg.useAuthelia then "true" else "false";
            APP_ENV = "prod";
            APP_TIMEZONE = "${config.mySystem.time.timeZone}";
            AUTH_METHOD = "LDAP";
            CALDAV_ENABLED = if cfg.caldavEnable then "true" else "false";
            CARDDAV_ENABLED = if cfg.carddavEnable then "true" else "false";
            DATABASE_DRIVER = "sqlite";
            DATABASE_URL = "sqlite:////config/davis-database.db";
            INVITE_FROM_ADDRESS = "${config.mySystem.notificationSender}";
            LDAP_AUTH_URL = "ldap://lldap:3890";
            LDAP_AUTH_USER_AUTOCREATE = "true";
            LDAP_DN_PATTERN = "uid=%U,ou=people,${config.mySystemApps.lldap.baseDN}";
            LDAP_MAIL_ATTRIBUTE = "mail";
            MAILER_DSN = "smtp://maddy:25";
            TRUSTED_HOSTS = "davis.${config.mySystem.rootDomain}";
            TRUSTED_PROXIES = "172.16.0.0/16";
            WEBDAV_ENABLED = if cfg.webdavEnable then "true" else "false";
            WEBDAV_HOMES_DIR = "";
            WEBDAV_PUBLIC_DIR = "/data";
            WEBDAV_TMP_DIR = "/tmp/webdav";
          };
          environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
          volumes = [
            "${cfg.dataDir}/config:/config"
            "${cfg.dataDir}/data:/data"
            "/var/cache/davis/web/public:/var/www/davis/public"
          ];
        };
      };

      services = {
        nginx.virtualHosts.davis = svc.mkNginxVHost {
          inherit (cfg) useAuthelia;

          host = "davis";
          proxyPass = "http://caddy.docker:8080";
          autheliaIgnorePaths = [
            "/dav"
            "/.well-known"
          ];
        };
        restic.backups = lib.mkIf cfg.backup (
          svc.mkRestic {
            name = "davis";
            paths = [ cfg.dataDir ];
          }
        );
      };

      systemd.services.docker-davis = {
        preStart =
          let
            dockerBin = lib.getExe pkgs."${config.virtualisation.oci-containers.backend}";
          in
          lib.mkAfter ''
            rm -rf /var/cache/davis/web || true
            mkdir -p "${cfg.dataDir}/config" "${cfg.dataDir}/data" /var/cache/davis/web
            chown 82:82 "${cfg.dataDir}/config" "${cfg.dataDir}/data" /var/cache/davis/web
            ${dockerBin} run --rm -v /var/cache/davis/web:/web ${image} /bin/sh -c "cp -a /var/www/davis/public /web"
            ${lib.getExe pkgs.gnused} -i 's@HEADER_X_FORWARDED_ALL@HEADER_X_FORWARDED_FOR@g' /var/cache/davis/web/public/index.php
          '';
      };

      environment.persistence."${config.mySystem.impermanence.persistPath}" =
        lib.mkIf config.mySystem.impermanence.enable
          { directories = [ cfg.dataDir ]; };

      mySystemApps.homepage = {
        services.Apps.Davis = svc.mkHomepage "davis" // {
          icon = "davis.png";
          description = "CardDAV, CalDAV and WebDAV";
        };
      };
    };
}
