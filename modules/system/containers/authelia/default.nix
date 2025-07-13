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
  usersDatabase = pkgs.writeText "users_database.yaml" (
    builtins.toJSON {
      users = builtins.listToAttrs (
        builtins.map (user: {
          name = user.username;
          value = {
            inherit (user) email groups;

            disabled = false;
            displayname = user.username;
            password = "@@AUTHELIA_USER_${user.username}_PASSWORD@@";
          };
        }) cfg.users
      );
    }
  );
  configuration = pkgs.writeText "configuration.yaml" (
    builtins.toJSON (
      lib.recursiveUpdate
        (svc.importYAML (
          svc.templateFile {
            name = "configuration.yaml";
            src = ./configuration.yaml;

            vars = {
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
          authentication_backend =
            lib.optionalAttrs (cfg.authenticationBackend == "ldap") {
              ldap = {
                implementation = "custom";
                address = "ldap://lldap:3890";
                timeout = "5s";
                start_tls = false;
                base_dn = config.mySystemApps.lldap.baseDN;
                additional_users_dn = "ou=people";
                users_filter = "(&({username_attribute}={input})(objectClass=person))";
                additional_groups_dn = "ou=groups";
                groups_filter = "(member={dn})";
                permit_referrals = false;
                permit_unauthenticated_bind = false;
                permit_feature_detection_failure = false;
                user = "uid=${config.mySystemApps.lldap.userDN},ou=people,${config.mySystemApps.lldap.baseDN}";
                attributes = {
                  display_name = "displayName";
                  group_name = "cn";
                  mail = "mail";
                  username = "uid";
                };
              };
            }
            // lib.optionalAttrs (cfg.authenticationBackend == "file") {
              file = lib.optionalAttrs (cfg.authenticationBackend == "file") {
                path = "/config/users_database.yml";
                watch = false;
              };
              password_change = {
                disable = true;
              };
              password_reset = {
                disable = true;
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
    authenticationBackend = lib.mkOption {
      type = lib.types.enum [
        "file"
        "ldap"
      ];
      description = "Which authentication backend to use.";
      default = if config.mySystemApps.lldap.enable then "ldap" else "file";
    };
    users = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.listOf (
          lib.types.submodule {
            options = {
              username = lib.mkOption {
                type = lib.types.str;
              };
              email = lib.mkOption {
                type = lib.types.str;
              };
              groups = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };
          }
        )
      );
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
        assertion = cfg.authenticationBackend != "ldap" || config.mySystemApps.lldap.enable;
        message = "To use LDAP backend, lldap container needs to be enabled.";
      }
      {
        assertion = cfg.authenticationBackend != "file" || (builtins.length cfg.users > 0);
        message = "To use FILE backend, at least one user must be defined.";
      }
    ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      secretEnvs =
        secretEnvs ++ (builtins.map (user: "AUTHELIA_USER_${user.username}_PASSWORD") cfg.users);

      containerName = "authelia";
    };

    mySystemApps = {
      postgresql.userDatabases = [
        {
          username = "authelia";
          passwordFile =
            config.sops.secrets."${cfg.sopsSecretPrefix}/AUTHELIA_STORAGE_POSTGRES_PASSWORD".path;
          databases = [ "authelia" ];
        }
      ];
      redis.servers.authelia = 6379;
    };

    virtualisation.oci-containers.containers.authelia = svc.mkContainer {
      cfg = {
        dependsOn = lib.optionals (cfg.authenticationBackend == "lldap") [ "lldap" ];
        user = "65000:65000";
        image = "ghcr.io/authelia/authelia:4.39.4@sha256:64b356c30fd817817a4baafb4dbc0f9f8702e46b49e1edb92ff42e19e487b517";
        environment =
          {
            AUTHELIA_STORAGE_POSTGRES_ADDRESS = "host.docker.internal";
            AUTHELIA_STORAGE_POSTGRES_DATABASE = "authelia";
            AUTHELIA_STORAGE_POSTGRES_USERNAME = "authelia";
            AUTHELIA_SESSION_REDIS_PASSWORD_FILE = "/secrets/AUTHELIA_SESSION_REDIS_PASSWORD";
            X_AUTHELIA_CONFIG_FILTERS = "template";
          }
          // (lib.optionalAttrs (cfg.authenticationBackend == "lldap") {
            AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "/secrets/AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD";
          })
          // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "/run/authelia/configuration.yaml:/config/configuration.yml"
            "${
              config.sops.secrets."${config.mySystemApps.redis.passFileSopsSecret}".path
            }:/secrets/AUTHELIA_SESSION_REDIS_PASSWORD:ro"
          ]
          ++ (lib.optionals (cfg.authenticationBackend == "lldap") [
            "${
              config.sops.secrets."${config.mySystemApps.lldap.sopsSecretPrefix}/LLDAP_LDAP_USER_PASS".path
            }:/secrets/AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD:ro"
          ])
          ++ (lib.optionals (cfg.authenticationBackend == "file") [
            "/run/authelia/users_database.yaml:/config/users_database.yml"
          ]);
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/config,tmpfs-mode=1777"
        ];
      };
    };

    systemd.services.docker-authelia = {
      preStart = lib.mkAfter (
        ''
          mkdir -p /run/authelia
          sed "s,@@AUTHELIA_IDENTITY_PROVIDERS_OIDC_JWKS_KEY@@,$(cat ${
            config.sops.secrets."${cfg.sopsSecretPrefix}/AUTHELIA_IDENTITY_PROVIDERS_OIDC_JWKS_KEY".path
          } | tr '\n' '#' | sed 's@#@\\\\n@g'),g" ${configuration} > /run/authelia/configuration.yaml

        ''
        + lib.optionalString (cfg.authenticationBackend == "file") (
          ''
            cat ${usersDatabase} > /run/authelia/users_database.yaml
          ''
          + (lib.concatStringsSep "\n" (
            builtins.map (user: ''
              sed -i"" "s#@@AUTHELIA_USER_${user.username}_PASSWORD@@#$(cat ${
                config.sops.secrets."${cfg.sopsSecretPrefix}/AUTHELIA_USER_${user.username}_PASSWORD".path
              })#g" /run/authelia/users_database.yaml
            '') cfg.users
          ))
        )
      );
    };

    services.nginx.virtualHosts.authelia = svc.mkNginxVHost {
      host = "authelia";
      proxyPass = "http://authelia.docker:9091";
      useAuthelia = false;
    };

    services.postgresqlBackup = lib.mkIf cfg.backup { databases = [ "authelia" ]; };
  };
}
