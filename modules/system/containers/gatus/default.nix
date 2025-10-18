{
  config,
  lib,
  svc,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.gatus;
  secretEnvs = [ "OIDC_SECRET_RAW" ];

  vhostNames = builtins.filter (
    name:
    (builtins.match "^[a-z0-9.-]+$" (
      builtins.toString (builtins.getAttr name config.services.nginx.virtualHosts).serverName
    )) != null
  ) (builtins.attrNames config.services.nginx.virtualHosts);
  endpoints =
    cfg.endpoints
    ++ (lib.optionals cfg.vhostsMonitoring.enable (
      builtins.map (
        name:
        let
          value = builtins.getAttr name config.services.nginx.virtualHosts;
        in
        {
          inherit name;

          url = (if value.addSSL then "https" else "http") + "://${value.serverName}/";
          interval = "30s";
          conditions =
            if (builtins.hasAttr name cfg.vhostsMonitoring.conditionsOverride) then
              (builtins.getAttr name cfg.vhostsMonitoring.conditionsOverride)
            else
              [ "[STATUS] < 300" ];
          alerts = [
            {
              type = "email";
              enabled = true;
            }
          ];
        }
      ) vhostNames
    ));

  configFile = pkgs.writeText "config" (
    builtins.toJSON {
      inherit endpoints;

      alerting = {
        email = {
          from = config.mySystem.notificationSender;
          host = "maddy";
          port = 25;
          to = builtins.concatStringsSep "," cfg.alertEmails;
        };
      };

      security = {
        oidc = {
          issuer-url = "https://authelia.${config.mySystem.rootDomain}";
          redirect-url = "https://gatus.${config.mySystem.rootDomain}/authorization-code/callback";
          client-id = "gatus";
          client-secret = "@@OIDC_SECRET_RAW@@";
          scopes = [ "openid" ];
        };
      };
    }
  );

in
{
  options.mySystemApps.gatus = {
    enable = lib.mkEnableOption "gatus container";
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/gatus/env";
    };
    alertEmails = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of emails receiving gatus alerts";
      default = [ ];
    };
    vhostsMonitoring = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "vhosts monitoring" // {
            default = true;
          };
          conditionsOverride = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
            description = "Custom set of conditions for given vhosts.";
            default = { };
            example = {
              "s3" = [ "[STATUS] == 403" ];
            };
          };
        };
      };
      default = {
        enable = true;
        conditionsOverride = { };
      };
    };

    endpoints = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "List of gatus endpoints";
      default = [ ];
      example = [
        {
          name = "redis";
          url = "tcp://redis:6397";
          interval = "30s";
          conditions = [ "[CONNECTED] == true" ];
          alerts = [
            {
              type = "email";
              enabled = true;
            }
          ];
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "gatus";
    };

    virtualisation.oci-containers.containers.gatus = svc.mkContainer {
      cfg = {
        image = "ghcr.io/twin/gatus:v5.27.0@sha256:5091320d752756d7ac0a094d26ac38eb8216d7ed5857642b305522d1c6641f72";
        user = "65000:65000";
        volumes = [ "/run/gatus/config.yaml:/config/config.yaml" ];
      };
      opts = {
        # allow monitoring external sources
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.gatus = svc.mkNginxVHost {
        host = "gatus";
        proxyPass = "http://gatus.docker:8080";
      };
    };

    systemd.services.docker-gatus = {
      preStart = lib.mkAfter ''
        mkdir -p /run/gatus
        sed "s,@@OIDC_SECRET_RAW@@,$(cat ${
          config.sops.secrets."${cfg.sopsSecretPrefix}/OIDC_SECRET_RAW".path
        }),g" ${configFile} > /run/gatus/config.yaml
        chown 65000:65000 /run/gatus /run/gatus/config.yaml
      '';
    };

    mySystemApps = {
      authelia.oidcClients = [
        {
          client_id = "gatus";
          client_name = "gatus";
          client_secret = "$pbkdf2-sha512$310000$JhhXnIo9eKxoiWr6inq0RA$F8RsVYb.CiBdbN7wH5q7tYLOGgx1yYcnz0fGRpPF./ix3BtSFj5P3CYnkI4XdkIyGRkUkQNb7hQhMU461zov4A"; # unencrypted version in SOPS
          consent_mode = "implicit";
          public = false;
          authorization_policy = "two_factor";
          redirect_uris = [
            "https://gatus.${config.mySystem.rootDomain}/authorization-code/callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      homepage = {
        services.Apps.Gatus = svc.mkHomepage "gatus" // {
          description = "Services monitoring";
          widget = {
            type = "gatus";
            url = "http://gatus:8080";
            fields = [
              "up"
              "down"
              "uptime"
            ];
          };
        };
      };
    };
  };
}
