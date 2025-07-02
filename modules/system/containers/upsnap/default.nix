{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.upsnap;
in
{
  options.mySystemApps.upsnap = {
    enable = lib.mkEnableOption "upsnap container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/upsnap";
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "Subdomain for ${config.mySystem.rootDomain}.";
      default = "upsnap";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for upsnap are disabled!") ];

    virtualisation.oci-containers.containers.upsnap = svc.mkContainer {
      cfg = {
        image = "ghcr.io/seriousm4x/upsnap:5.1.1@sha256:757076afc15f20e5f2c3372424850b79eb10fea4975ad3a1209ee3fb39484a39";
        user = "65000:65000";
        environment = {
          UPSNAP_INTERVAL = "*/30 * * * * *"; # 30 sec
          UPSNAP_SCAN_RANGE = config.myInfra.cidrs.trusted;
          UPSNAP_PING_PRIVILEGED = "false";
        };
        volumes = [ "${cfg.dataDir}/:/app/pb_data" ];
        extraOptions = [
          "--cap-add=CAP_NET_RAW"
          "--no-healthcheck"
        ];
        entrypoint = "";
        cmd = [
          "/app/upsnap"
          "serve"
          "--http=0.0.0.0:8899"
        ]; # 8090 is occupied by beszel agent
      };
      opts = {
        # for sending WoL packets
        useHostNetwork = true;
      };
    };

    services = {
      nginx.virtualHosts.upsnap = svc.mkNginxVHost {
        host = cfg.subdomain;
        proxyPass = "http://127.0.0.1:8899"; # because host network
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "upsnap";
          paths = [ cfg.dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              user = config.users.users.abc.name;
              group = config.users.groups.abc.name;
              directory = cfg.dataDir;
              mode = "750";
            }
          ];
        };

    mySystemApps = {
      authelia.oidcClients = [
        {
          client_id = "upsnap";
          client_name = "Upsnap";
          client_secret = "$pbkdf2-sha512$310000$kFL55egfYYGzg/TONdB9Dg$DKbwxUqOqUB2XyuTegfmF5kUia0MTjjV0YIY1dbRJCLhP9Wi.SUdGIOy/ablnm41UyP4XN2mB7WXpDDPaaA4Wg"; # unencrypted version in SOPS
          consent_mode = "implicit";
          public = false;
          authorization_policy = "two_factor";
          require_pkce = false;
          redirect_uris = [
            "https://${cfg.subdomain}.${config.mySystem.rootDomain}/api/oauth2-redirect"
          ];
          scopes = [
            "email"
            "openid"
            "profile"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];
      homepage = {
        services.Apps.Upsnap = svc.mkHomepage cfg.subdomain // {
          description = "WakeOnLan tool";
          icon = "upsnap.svg";
        };
      };
    };
  };
}
