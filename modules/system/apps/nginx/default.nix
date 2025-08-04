{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.nginx;
in
{
  options.mySystemApps.nginx = {
    enable = lib.mkEnableOption "nginx";
    rootDomain = lib.mkOption {
      type = lib.types.str;
      description = "TLD of all vhost subdomains.";
    };
    defaultCSPHeader = lib.mkOption {
      type = lib.types.str;
      default = ''
        default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data: mediastream: blob: wss: https://*.${cfg.rootDomain};
        object-src 'none';
      '';
      description = "Default CSP header for all VHosts (can be overriden per vhost).";
    };
    extraVHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            target = lib.mkOption {
              type = lib.types.str;
              description = "Target for the VHost.";
              example = "http://service.somewhere:1234";
            };
            extraConfig = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Extra configuration for VHost.";
              example = "rewrite ^/$ /index.html break;";
            };
          };
        }
      );
      description = "Extra VHosts to be configured with proxy pass.";
      default = { };
      example = {
        "myhost" = {
          target = "http://service.somewhere:1234";
          extraConfig = "rewrite ^/$ /index.html break;";
        };
      };
    };
    extraRedirects = lib.mkOption {
      type = lib.types.attrs;
      description = "Extra redirects to be configured.";
      default = { };
      example = {
        "myhost" = "http://service.somewhere:1234";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      group = "services";
      package = pkgs.nginxStable.override { openssl = pkgs.libressl; };

      clientMaxBodySize = "0"; # disable file upload limits

      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;

      # harden TLS
      recommendedTlsSettings = false; # OCSP stapling is PITA
      sslProtocols = "TLSv1.2 TLSv1.3";
      sslCiphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305";
      commonHttpConfig = ''
        # Keep in sync with https://ssl-config.mozilla.org/#server=nginx&config=intermediate

        ssl_ecdh_curve X25519:prime256v1:secp384r1;

        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:10m;
        # Breaks forward secrecy: https://github.com/mozilla/server-side-tls/issues/135
        ssl_session_tickets off;

        # We don't enable insecure ciphers by default, so this allows
        # clients to pick the most performant, per https://github.com/mozilla/server-side-tls/issues/260
        ssl_prefer_server_ciphers off;
      '';

      appendHttpConfig = ''
        map $scheme $hsts_header {
            https   "max-age=31536000; includeSubdomains";
        }
        more_set_headers "Strict-Transport-Security: $hsts_header";

        # Enable CSP for your services.
        more_set_headers "Content-Security-Policy: ${
          lib.trim (builtins.replaceStrings [ "\n" ] [ " " ] cfg.defaultCSPHeader)
        }";

        # Prevent injection of code in other mime types (XSS Attacks)
        more_set_headers "X-Content-Type-Options: nosniff";

        # Minimize information leaked to other domains
        more_set_headers "Referrer-Policy: origin-when-cross-origin";
      '';

      eventsConfig = ''
        worker_connections 4096;
      '';

      virtualHosts =
        lib.recursiveUpdate
          (builtins.mapAttrs (
            name: value:
            svc.mkNginxVHost {
              inherit (value) extraConfig;
              host = name;
              proxyPass = value.target;
              useAuthelia = false;
              customCSP = "disable";
            }
          ) cfg.extraVHosts)
          (
            builtins.mapAttrs (name: value: {
              useACMEHost = "wildcard.${config.mySystem.rootDomain}";
              serverName = "${name}.${config.mySystem.rootDomain}";
              forceSSL = true;
              # globalRedirect is borked, and forces https on redirected host host as well, which me not always be the case
              locations."/".extraConfig = ''
                return 301 ${value}$request_uri;
              '';
            }) cfg.extraRedirects
          );
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };

}
