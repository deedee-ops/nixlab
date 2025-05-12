{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.memos;
  secretEnvs = [
    "MEMOS__POSTGRES_PASSWORD"
  ];
in
{
  options.mySystemApps.memos = {
    enable = lib.mkEnableOption "memos container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/memos";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/memos/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for memos are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "memos";
    };

    mySystemApps = {
      postgresql.userDatabases = [
        {
          username = "memos";
          passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/MEMOS__POSTGRES_PASSWORD".path;
          databases = [ "memos" ];
        }
      ];

      authelia.oidcClients = [
        {
          client_id = "memos";
          client_name = "memos";
          client_secret = "$pbkdf2-sha512$310000$jqwbJX/ZQLhgsXukrVQFeg$oa8TtKf4/LGC.Z32SfqFIj.vq2TvCOtcD6WEE2FTKAwguPOysiZtTKV7CEYnaMP47rpEGyejy2lRBVilKzwGnA"; # unencrypted version in SOPS
          consent_mode = "implicit";
          public = false;
          authorization_policy = "two_factor";
          redirect_uris = [
            "https://memos.${config.mySystem.rootDomain}/auth/callback"
          ];
          scopes = [
            "email"
            "openid"
            "profile"
          ];
          token_endpoint_auth_method = "client_secret_post";
        }
      ];
    };

    virtualisation.oci-containers.containers.memos = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/memos:0.24.2@sha256:b0bb031e3433a06b12a0ca0149d805a7241c8b260821cd18faba12799d03df20";
        environment = {
          MEMOS_DRIVER = "postgres";
          MEMOS_MODE = "prod";
          MEMOS_DATA = "/var/opt/memos";
          MEMOS__POSTGRES_DATABASE = "memos";
          MEMOS__POSTGRES_HOST = "host.docker.internal";
          MEMOS__POSTGRES_SSLMODE = "disable";
          MEMOS__POSTGRES_USERNAME = "memos";
        } // svc.mkContainerSecretsEnv { inherit secretEnvs; };
        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [ "${cfg.dataDir}:/var/opt/memos" ];
        extraOptions = [
          "--add-host=authelia.${config.mySystem.rootDomain}:${config.mySystemApps.docker.network.private.hostIP}"
        ];
      };
      opts = {
        # access to S3 buckets
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.memos = svc.mkNginxVHost {
        host = "memos";
        proxyPass = "http://memos.docker:5230";
        autheliaIgnorePaths = [ "/api" ];
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "memos" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "memos";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-memos = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}"
        chown 65000:65000 "${cfg.dataDir}"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.Memos = svc.mkHomepage "memos" // {
        icon = "memos.png";
        description = "Quick notes";
      };
    };
  };
}
