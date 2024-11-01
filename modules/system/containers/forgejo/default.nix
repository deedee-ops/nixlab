{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.forgejo;
  secretEnvs = [
    "FORGEJO__cache__HOST"
    "FORGEJO__database__PASSWD"
    "FORGEJO__oauth2__JWT_SECRET"
    "FORGEJO__queue__CONN_STR"
    "FORGEJO__security__INTERNAL_TOKEN"
    "FORGEJO__security__SECRET_KEY"
    "FORGEJO__server__LFS_JWT_SECRET"
    "FORGEJO__session__PROVIDER_CONFIG"
  ];
in
{
  options.mySystemApps.forgejo = {
    enable = lib.mkEnableOption "forgejo container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/forgejo";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/forgejo/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for forgejo are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "forgejo";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "forgejo";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/FORGEJO__database__PASSWD".path;
        databases = [ "forgejo" ];
      }
    ];

    virtualisation.oci-containers.containers.forgejo = svc.mkContainer {
      cfg = {
        image = "codeberg.org/forgejo/forgejo:9.0.1-rootless@sha256:871b9ee033bbce261cb8306240f05cc902c118b40ddba2a72d8111f1ba0fe30e";
        environment =
          {
            FORGEJO__server__DOMAIN = "git.${config.mySystem.rootDomain}";
            FORGEJO__server__SSH_DOMAIN = "git.${config.mySystem.rootDomain}";
            FORGEJO__server__ROOT_URL = "https://git.${config.mySystem.rootDomain}";
            FORGEJO__mailer__FROM = config.mySystem.notificationSender;
            FORGEJO__time__DEFAULT_UI_LOCATION = config.mySystem.time.timeZone;
          }
          // svc.mkContainerSecretsEnv {
            inherit secretEnvs;
            suffix = "__FILE";
          };
        ports = [ "2222:2222" ];
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [ "${cfg.dataDir}:/var/lib/gitea" ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
      opts = {
        # to expose port to host, public network must be used
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.forgejo = svc.mkNginxVHost {
        host = "git";
        proxyPass = "http://forgejo.docker:3000";
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "forgejo" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "forgejo";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-forgejo = {
      path = [ pkgs.diffutils ];
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/custom/conf"
        cp ${./app.ini} "${cfg.dataDir}/custom/conf/app.ini"
        chown 1000:1000 "${cfg.dataDir}" "${cfg.dataDir}/custom" "${cfg.dataDir}/custom/conf" "${cfg.dataDir}/custom/conf/app.ini"
        chmod 640 "${cfg.dataDir}/custom/conf/app.ini"

        # ugly hack to fix forgejo permissions, as sops-nix doesn't allow setting direct UID/GID yet
        chown -R 1000:1000 "$(dirname ${
          config.sops.secrets."${cfg.sopsSecretPrefix}/${builtins.elemAt secretEnvs 0}".path
        })"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.Forgejo = svc.mkHomepage "forgejo" // {
        href = "https://git.${config.mySystem.rootDomain}";
        description = "Git repositories";
      };
    };
  };
}
