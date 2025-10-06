{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.airtrail;
  secretEnvs = [
    "AIRTRAIL__POSTGRES_PASSWORD"
    "DB_URL"
    "INTEGRATIONS_AERO_DATA_BOX_KEY"
    "OAUTH_CLIENT_SECRET"
  ];
in
{
  options.mySystemApps.airtrail = {
    enable = lib.mkEnableOption "airtrail container";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/airtrail/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for airtrail are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "airtrail";
    };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "airtrail";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/AIRTRAIL__POSTGRES_PASSWORD".path;
        databases = [ "airtrail" ];
      }
    ];

    virtualisation.oci-containers.containers.airtrail = svc.mkContainer {
      cfg = {
        image = "johly/airtrail:v3.1.2@sha256:d0edb812914dfac2b528c94952dcfeb1b9c676abb04e7f975cf74fe7e582dc7f";
        environment = {
          ORIGIN = "https://airtrail.${config.mySystem.rootDomain}";
          OAUTH_ENABLED = "true";
          OAUTH_AUTO_LOGIN = "true";
          OAUTH_AUTO_REGISTER = "false";
          OAUTH_CLIENT_ID = "airtrail";
          OAUTH_ISSUER_URL = "https://authelia.${config.mySystem.rootDomain}";
          OAUTH_SCOPE = "openid profile";
        };
      };
      opts = {
        inherit (cfg) sopsSecretPrefix;
        inherit secretEnvs;

        # fetch airports
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.airtrail = svc.mkNginxVHost {
        host = "airtrail";
        proxyPass = "http://airtrail.docker:3000";
        customCSP = ''
          default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data:
          mediastream: blob: wss: https://basemaps.cartocdn.com https://*.basemaps.cartocdn.com
          https://flagcdn.com https://*.${config.mySystem.rootDomain}; object-src 'none';
        '';
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "airtrail" ]; };
    };

    mySystemApps = {
      authelia.oidcClients = [
        {
          client_id = "airtrail";
          client_name = "airtrail";
          client_secret = "$pbkdf2-sha512$310000$wehFIskEzBK/b4WdMI9OPQ$CysJQFzBBlnAireIHG4gkVt3dOYZKW5EmrUR2ys/5hpwLHHlViU5fOJzCV112tTZc4aPSU405SSg0uOvyrXv.Q"; # unencrypted version in SOPS
          consent_mode = "implicit";
          public = false;
          authorization_policy = "two_factor";
          redirect_uris = [
            "https://airtrail.${config.mySystem.rootDomain}/login"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
      ];

      homepage = {
        services.Apps.AirTrail = svc.mkHomepage "airtrail" // {
          icon = "air-trail.svg";
          description = "Flight Tracker";
        };
      };
    };
  };
}
