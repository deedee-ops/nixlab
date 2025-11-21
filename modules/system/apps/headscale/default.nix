{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.headscale;
in
{
  options.mySystemApps.headscale = {
    enable = lib.mkEnableOption "headscale app";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    nameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Upstream nameservers used by tailscale and exposed for tailscale clients.";
      default = config.networking.nameservers;
      example = [
        "9.9.9.9"
        "149.112.112.112"
      ];
    };
    oidc = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "OIDC configuration for headplane";
          clientId = lib.mkOption {
            type = lib.types.str;
            description = "Client ID";
          };
          issuer = lib.mkOption {
            type = lib.types.str;
            description = "Issuer host (without proto part)";
            example = "auth.example.com";
          };
        };
      };
      default = { };
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, containing headscale and headplane secrets.";
      default = "system/apps/headscale";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      let
        secretParams = {
          owner = "headscale";
          group = "headscale";
          mode = "0640";
        };
      in
      {
        "${cfg.sopsSecretPrefix}/headplane/cookie_secret" = secretParams;
        "${cfg.sopsSecretPrefix}/headplane/oidc_client_secret" = secretParams;
      };

    services = {
      headscale = {
        enable = true;
        address = "127.0.48.80";
        port = 48080;
        settings = {
          server_url = "https://headscale.${config.mySystem.rootDomain}";
          logtail.enabled = false;
          dns = {
            base_domain = "headnet.${config.mySystem.rootDomain}";
            nameservers.global = cfg.nameservers;
          };
        };
      };

      headplane =
        let
          format = pkgs.formats.yaml { };
          # A workaround generate a valid Headscale config accepted by Headplane when `config_strict == true`.
          headscaleSettings = lib.recursiveUpdate config.services.headscale.settings {
            oidc.client_secret_path = "/dev/null";
            policy.path = "/dev/null";
            tls_cert_path = "/dev/null";
            tls_key_path = "/dev/null";
          };

          headscaleConfig = format.generate "headscale.yml" headscaleSettings;
        in
        {
          enable = true;
          settings = {
            server = {
              host = "127.0.0.1";
              port = 43000;
              cookie_secret_path = config.sops.secrets."${cfg.sopsSecretPrefix}/headplane/cookie_secret".path;
              cookie_secure = true;
            };
            headscale = {
              url = "http://${config.services.headscale.address}:${toString config.services.headscale.port}";
              public_url = config.services.headscale.settings.server_url;
              config_path = headscaleConfig;
            };
            integration = {
              agent = {
                enabled = true;
                pre_authkey_path = "/var/lib/headplane/agent_preauth_key";
              };
              proc.enabled = true;
            };
            oidc = lib.optionalAttrs cfg.oidc.enable {
              client_id = cfg.oidc.clientId;
              client_secret_path =
                config.sops.secrets."${cfg.sopsSecretPrefix}/headplane/oidc_client_secret".path;
              disable_api_key_login = true;
              headscale_api_key_path = "/var/lib/headplane/headscale_api_key";
              issuer = "https://${cfg.oidc.issuer}";
              redirect_uri = "${config.services.headscale.settings.server_url}/admin/oidc/callback";
              token_endpoint_auth_method = "client_secret_post";
            };
          };
        };

      nginx.virtualHosts = {
        headscale =
          lib.recursiveUpdate
            (svc.mkNginxVHost {
              host = "headscale";
              proxyPass = "http://${config.services.headscale.address}:${toString config.services.headscale.port}";
              useAuthelia = false;
            })
            {
              locations."/admin".extraConfig = ''
                set $host_to_pass http://${config.services.headplane.settings.server.host}:${toString config.services.headplane.settings.server.port}; # backend
                proxy_pass $host_to_pass;

                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_set_header Host $host;
                proxy_redirect http:// https://;
                proxy_buffering off;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                more_set_headers "Content-Security-Policy: default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data: mediastream: blob: wss: https://*.${config.mySystem.rootDomain} ${lib.optionalString cfg.oidc.enable "https://${cfg.oidc.issuer}"};; object-src 'none';";
              '';
            };
      };

      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "headscale";
          paths = [ "/var/lib/headscale" ];
        }
      );
    };

    systemd.services = lib.mkIf (!config.mySystem.recoveryMode) {
      headplane = {
        preStart =
          let
            headscaleBin = lib.getExe config.services.headscale.package;
          in
          ''
            if [ ! -f /var/lib/headplane/headscale_api_key ]; then
              mkdir -p /var/lib/headplane
              ${headscaleBin} apikeys create > /var/lib/headplane/headscale_api_key
              chown headscale:headscale /var/lib/headplane/headscale_api_key
            fi

            [ -f /var/lib/headplane/agent_preauth_key ] && exit 0
            ${headscaleBin} users create headplane-agent
            sleep 1
            id="$(${headscaleBin} users list -o json | ${lib.getExe pkgs.jq} '.[] | select(.name == "headplane-agent").id')"
            echo "ID: $id"
            ${headscaleBin} preauthkeys create -u "$id" --reusable -e 100y | tail -n 1 > /var/lib/headplane/agent_preauth_key
            chown headscale:headscale /var/lib/headplane/agent_preauth_key
          '';
      };
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              inherit (config.services.headscale) user group;
              directory = "/var/lib/headscale";
              mode = "700";
            }
          ];
        };
  };
}
