{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.lldap;
  secretEnvs = [
    "LLDAP_DATABASE_PASSWORD"
    "LLDAP_JWT_SECRET"
    "LLDAP_KEY"
    "LLDAP_LDAP_USER_PASS"
  ];
in
{
  options.mySystemApps.lldap = {
    enable = lib.mkEnableOption "lldap container";
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/lldap/env";
    };
    baseDN = lib.mkOption {
      type = lib.types.str;
      default = "dc=home,dc=arpa";
    };
    userDN = lib.mkOption {
      type = lib.types.str;
      default = "manage";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "lldap";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "lldap";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/LLDAP_DATABASE_PASSWORD".path;
        databases = [ "lldap" ];
      }
    ];

    virtualisation.oci-containers.containers.lldap = svc.mkContainer {
      cfg = rec {
        image = "ghcr.io/deedee-ops/lldap:2024.10.16@sha256:a07225292b357326ed44be81fc559edeacb3bbcca3df8c0127b5566e969e4c5b";
        environment = {
          LLDAP_VERBOSE = "false";
          LLDAP_HTTP_URL = "http://lldap.${config.mySystem.rootDomain}";

          LLDAP_DATABASE_DRIVER = "postgres";
          LLDAP_DATABASE_USERNAME = "lldap";
          LLDAP_DATABASE_HOST = "host.docker.internal";
          LLDAP_DATABASE_DBNAME = "lldap";

          LLDAP_LDAPS_OPTIONS__ENABLED = "false";

          LLDAP_LDAP_BASE_DN = cfg.baseDN;
          LLDAP_LDAP_USER_DN = cfg.userDN;
          LLDAP_LDAP_USER_EMAIL = "${environment.LLDAP_LDAP_USER_DN}@${config.mySystem.rootDomain}";

          LLDAP_SMTP_OPTIONS__ENABLE_PASSWORD_RESET = "true";
          LLDAP_SMTP_OPTIONS__FROM = config.mySystem.notificationSender;
          LLDAP_SMTP_OPTIONS__PORT = "25";
          LLDAP_SMTP_OPTIONS__SERVER = "host.docker.internal";
          LLDAP_SMTP_OPTIONS__SMTP_ENCRYPTION = "NONE";
        } // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes = svc.mkContainerSecretsVolumes {
          inherit (cfg) sopsSecretPrefix;
          inherit secretEnvs;
        };
      };
    };

    services.nginx.virtualHosts.lldap = svc.mkNginxVHost "lldap" "http://lldap.docker:17170";
  };
}
