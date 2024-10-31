{
  config,
  lib,
  pkgs,
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
  configuration = pkgs.writeText "configuration.yaml" (
    builtins.toJSON (
      lib.recursiveUpdate
        (svc.importYAML (
          svc.templateFile {
            name = "configuration.yaml";
            src = ./configuration.yaml;

            vars = {
              LLDAP_LDAP_BASE_DN = config.mySystemApps.lldap.baseDN;
              LLDAP_LDAP_USER_DN = config.mySystemApps.lldap.userDN;
              NOTIFICATION_SENDER = config.mySystem.notificationSender;
              ROOT_DOMAIN = config.mySystem.rootDomain;
            };
          }
        ))
        {
          identity_providers = {
            oidc = {
              clients = cfg.oidcClients;
            };
          };
        }

    )
  );
in
{
  options.mySystemApps.authelia = {
    enable = lib.mkEnableOption "authelia container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/authelia/env";
    };
    oidcClients = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Extra OIDC clients configuration.";
      default = [
        {
          client_id = "dummy";
          # dummy secret to silence validator
          client_secret = "$pbkdf2-sha512$310000$Ba.BvSfTLFe13NgdaYAuzQ$8hXUp.8taU1rQ314hWbd9ku..inwUSMhhLnLYJDkkdSL1FXi5rIO7aErr91d7kvp4BLReZWmBFe.8Cg6zsEwLg";
        }
      ];
      example = [
        {
          client_id = "example";
          client_name = "Example";
          client_secret = "Encrypted client secret";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for authelia are disabled!") ];
    assertions = [
      {
        assertion = config.mySystemApps.lldap.enable;
        message = "To use authelia, lldap container needs to be enabled.";
      }
    ];

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
        image = "ghcr.io/deedee-ops/authelia:4.38.17@sha256:9496753299810eac43543053c03afc6b28da3c08098750ca840324ef66d67cc2";
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
            "/run/authelia/configuration.yaml:/config/configuration.yaml:ro"
            "${
              config.sops.secrets."${config.mySystemApps.lldap.sopsSecretPrefix}/LLDAP_LDAP_USER_PASS".path
            }:/secrets/AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD:ro"
            "${
              config.sops.secrets."${config.mySystemApps.redis.passFileSopsSecret}".path
            }:/secrets/AUTHELIA_SESSION_REDIS_PASSWORD:ro"
          ];
      };
    };

    systemd.services.docker-authelia = {
      preStart = lib.mkAfter ''
        mkdir -p /run/authelia
        sed "s,@@AUTHELIA_IDENTITY_PROVIDERS_OIDC_JWKS_KEY@@,$(cat ${
          config.sops.secrets."${cfg.sopsSecretPrefix}/AUTHELIA_IDENTITY_PROVIDERS_OIDC_JWKS_KEY".path
        } | tr '\n' '#' | sed 's@#@\\\\n@g'),g" ${configuration} > /run/authelia/configuration.yaml
      '';
    };

    services.nginx.virtualHosts.authelia = svc.mkNginxVHost {
      host = "authelia";
      proxyPass = "http://authelia.docker:9091";
      useAuthelia = false;
    };

    services.postgresqlBackup = lib.mkIf cfg.backup { databases = [ "authelia" ]; };
  };
}
