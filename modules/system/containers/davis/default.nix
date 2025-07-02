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
    useAuthelia = lib.mkEnableOption "authelia";
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

  config =
    let
      image = "ghcr.io/deedee-ops/davis:5.0.2@sha256:a8b7464fa65196cb304610f5cf0b0e82b71c7214632371b53444d05e4c9ab2fa";
    in
    lib.mkIf cfg.enable {
      warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for davis are disabled!") ];

      sops.secrets."${cfg.envFileSopsSecret}" = { };

      virtualisation.oci-containers.containers.davis = svc.mkContainer {
        cfg = {
          inherit image;

          dependsOn = [ "lldap" ];
          environment = {
            ADMIN_AUTH_BYPASS = if cfg.useAuthelia then "true" else "false";
            APP_TIMEZONE = "${config.mySystem.time.timeZone}";
            AUTH_METHOD = "LDAP";
            CALDAV_ENABLED = if cfg.caldavEnable then "true" else "false";
            CARDDAV_ENABLED = if cfg.carddavEnable then "true" else "false";
            INVITE_FROM_ADDRESS = "${config.mySystem.notificationSender}";
            LDAP_AUTH_URL = "ldap://lldap:3890";
            LDAP_AUTH_USER_AUTOCREATE = "true";
            LDAP_DN_PATTERN = "uid=%U,ou=people,${config.mySystemApps.lldap.baseDN}";
            LDAP_MAIL_ATTRIBUTE = "mail";
            MAILER_DSN = "smtp://maddy:25";
            TRUSTED_HOSTS = "davis.${config.mySystem.rootDomain}";
            TRUSTED_PROXIES = "172.16.0.0/16";
            WEBDAV_ENABLED = if cfg.webdavEnable then "true" else "false";
            WEBDAV_HOMES_DIR = "/webdav";
          };
          environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
          volumes = [
            "${cfg.dataDir}/config:/config"
            "${cfg.webdavDir}:/webdav"
          ];
        };
      };

      services = {
        nginx.virtualHosts.davis = svc.mkNginxVHost {
          inherit (cfg) useAuthelia;

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
          chown 65000:65000 "${cfg.dataDir}/config" "${cfg.webdavDir}"
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
