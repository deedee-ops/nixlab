{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.authelia;
  secretEnvs = [
    "AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET"
    "AUTHELIA_IDENTITY_PROVIDERS_OIDC_JWKS_KEY"
    "AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET"
    "AUTHELIA_SESSION_SECRET"
    "AUTHELIA_STORAGE_ENCRYPTION_KEY"
    "AUTHELIA_STORAGE_POSTGRES_PASSWORD"
  ];
  configuration = svc.templateFile {
    name = "configuration.yaml";
    src = ./configuration.yaml;

    vars = {
      LLDAP_LDAP_BASE_DN = config.mySystemApps.lldap.baseDN;
      LLDAP_LDAP_USER_DN = config.mySystemApps.lldap.userDN;
      NOTIFICATION_SENDER = config.mySystem.notificationSender;
      ROOT_DOMAIN = config.mySystem.rootDomain;
    };
  };
in
{
  options.mySystemApps.authelia = {
    enable = lib.mkEnableOption "authelia container";
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/authelia/env";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "authelia";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "authelia";
        passwordFile =
          config.sops.secrets."${cfg.sopsSecretPrefix}/AUTHELIA_STORAGE_POSTGRES_PASSWORD".path;
        databases = [ "authelia" ];
      }
    ];

    virtualisation.oci-containers.containers.authelia = svc.mkContainer {
      cfg = {
        dependsOn = [ "lldap" ];
        image = "ghcr.io/deedee-ops/authelia:4.38.15@sha256:d8a4bcfe713e23b68d6b0d215906e46959c39b1a1ade8e8328fe548ce417db98";
        environment = {
          AUTHELIA_STORAGE_POSTGRES_ADDRESS = "host.docker.internal";
          AUTHELIA_STORAGE_POSTGRES_DATABASE = "authelia";
          AUTHELIA_STORAGE_POSTGRES_USERNAME = "authelia";
          X_AUTHELIA_CONFIG_FILTERS = "template";
        }; # // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${configuration}:/config/configuration.yaml:ro"
            "${
              config.sops.secrets."${config.mySystemApps.lldap.sopsSecretPrefix}/LLDAP_LDAP_USER_PASS".path
            }:/secrets/AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD:ro"
            "${
              config.sops.secrets."${config.mySystemApps.redis.passFileSopsSecret}".path
            }:/secrets/AUTHELIA_SESSION_REDIS_PASSWORD:ro"
          ];
      };
    };

    services.nginx.virtualHosts.authelia = svc.mkNginxVHost "authelia" "http://authelia.docker:9091";
  };
}
