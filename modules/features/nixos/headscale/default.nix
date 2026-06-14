_: {
  flake.nixosModules.features-nixos-headscale =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.nixos.headscale;
    in
    {
      options.features.nixos.headscale = {
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
        serverHost = lib.mkOption {
          type = lib.types.str;
          description = "Headscale server Host.";
          example = "headscale.example.com";
        };
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
        };
      };

      config = {
        sops.secrets =
          lib.genAttrs
            [
              "features/nixos/headplane/cookieSecret"
              "features/nixos/headplane/oidcClientSecret"
              "features/nixos/headplane/caddyEnv"
            ]
            (_: {
              owner = "headscale";
              group = "headscale";
              mode = "0640";
              sopsFile = cfg.sopsSecretsFile;
            });

        services = {
          caddy = {
            enable = true;
            package = pkgs.caddy.withPlugins {
              plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
              hash = "sha256-8yZDrejNKsaUnUaTUFYbarWNmxafqp2z2rWo+XRsxV8=";
            };
            virtualHosts."${cfg.serverHost}".extraConfig = ''
              tls {
                dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
              }
              handle /admin* {
                reverse_proxy http://${config.services.headplane.settings.server.host}:${toString config.services.headplane.settings.server.port}
              }
              handle {
                reverse_proxy http://${config.services.headscale.address}:${toString config.services.headscale.port}
              }
            '';
          };
          headscale = {
            enable = true;
            address = "127.0.48.80";
            port = 48080;
            settings = {
              server_url = "https://${cfg.serverHost}";
              logtail.enabled = false;
              dns = {
                magic_dns = false;
                base_domain = "internal";
                nameservers.global = cfg.nameservers;
              };
            };
          };

          headplane = {
            enable = true;
            settings = {
              server = {
                base_url = "https://${cfg.serverHost}";
                host = "127.0.0.1";
                port = 43000;
                cookie_secret_path = config.sops.secrets."features/nixos/headplane/cookieSecret".path;
                cookie_secure = true;
              };
              headscale = {
                url = "http://${config.services.headscale.address}:${toString config.services.headscale.port}";
                public_url = config.services.headscale.settings.server_url;
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
                client_secret_path = config.sops.secrets."features/nixos/headplane/oidcClientSecret".path;
                disable_api_key_login = false;
                headscale_api_key_path = "/var/lib/headplane/headscale_api_key";
                issuer = "https://${cfg.oidc.issuer}";
                token_endpoint_auth_method = "client_secret_post";
              };
            };
          };
        };

        systemd.services = {
          caddy.serviceConfig.EnvironmentFile = config.sops.secrets."features/nixos/headplane/caddyEnv".path;
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

        networking.firewall = {
          allowedTCPPorts = [
            80
            443
          ];
          trustedInterfaces = [ "tailscale0" ];
        };
      };
    };
}
