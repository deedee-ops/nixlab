{
  config,
  lib,
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
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/davis";
    };
    webdavDir = lib.mkOption {
      type = lib.types.str;
      description = ''
        Path to directory containing webdav files.
        IMPERMANENCE FOR THIS DIR IS NOT ENABLED UNLESS IT'S A SUBDIR OF `cfg.dataDir`.
      '';
      default = "${cfg.dataDir}/data";
    };
    webdavDirBackup = lib.mkOption {
      type = lib.types.bool;
      description = "Include webdav dir in backups.";
      default = true;
    };
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing redlib envs.";
      default = "system/apps/davis/envfile";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for davis are disabled!") ];

    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.davis = svc.mkContainer {
      cfg = {
        image = "ghcr.io/tchapi/davis-standalone:5.2.0@sha256:fbf979409df57aa39a46201e05b37aca3feb47ea11f18b4e4c6e01d21aae6ea6";
        dependsOn = lib.optionals config.mySystemApps.lldap.enable [ "lldap" ];
        environment = {
          ADMIN_AUTH_BYPASS = if config.mySystemApps.authelia.enable then "true" else "false";
          APP_ENV = "prod";
          APP_TIMEZONE = "${config.mySystem.time.timeZone}";
          BIRTHDAY_REMINDER_OFFSET = "false";
          CALDAV_ENABLED = if cfg.caldavEnable then "true" else "false";
          CARDDAV_ENABLED = if cfg.carddavEnable then "true" else "false";
          DATABASE_DRIVER = "sqlite";
          DATABASE_URL = "sqlite:////config/davis-database.db";
          INVITE_FROM_ADDRESS = "${config.mySystem.notificationSender}";
          LOG_FILE_PATH = "/tmp/davis.log";
          MAILER_DSN = "smtp://maddy:25";
          TRUSTED_HOSTS = "davis.${config.mySystem.rootDomain}";
          TRUSTED_PROXIES = "172.16.0.0/16";
          UMASK = "0002";
          WEBDAV_ENABLED = if cfg.webdavEnable then "true" else "false";
          WEBDAV_HOMES_DIR = "/webdav";
          WEBDAV_PUBLIC_DIR = "/data";
          WEBDAV_TMP_DIR = "/tmp/webdav";
        }
        // (lib.optionalAttrs config.mySystemApps.lldap.enable {
          AUTH_METHOD = "LDAP";
          LDAP_AUTH_URL = "ldap://lldap:3890";
          LDAP_AUTH_USER_AUTOCREATE = "true";
          LDAP_DN_PATTERN = "uid=%U,ou=people,${config.mySystemApps.lldap.baseDN}";
          LDAP_MAIL_ATTRIBUTE = "mail";
        })
        // (lib.optionalAttrs (!config.mySystemApps.lldap.enable) {
          AUTH_REALM = "SabreDAV";
          AUTH_METHOD = "Basic";
        });
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
        volumes = [
          "${cfg.dataDir}/config:/config"
          "${cfg.webdavDir}:/webdav"
        ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--mount"
          "type=tmpfs,destination=/data,tmpfs-mode=1777"
          "--mount"
          "type=tmpfs,destination=/tmp/webdav,tmpfs-mode=1777"
        ];
      };
      opts = {
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.davis = svc.mkNginxVHost {
        useAuthelia = config.mySystemApps.authelia.enable;

        host = "davis";
        proxyPass = "http://davis.docker:9000";
        autheliaIgnorePaths = [
          "/dav"
          "/.well-known"
        ];
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "davis";
          fullPaths = lib.optionals cfg.webdavDirBackup [ cfg.webdavDir ];
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-davis = {
      preStart = lib.mkAfter ''
        rm -rf /var/cache/davis/web || true
        mkdir -p "${cfg.dataDir}/config"
        [ ! -d "${cfg.webdavDir}" ] && mkdir -p "${cfg.webdavDir}"
        chown 82:82 "${cfg.dataDir}/config" "${cfg.webdavDir}"
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
