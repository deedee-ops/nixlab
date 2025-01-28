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
      type = lib.types.attrs;
      description = "Extra VHosts to be configured with proxy pass.";
      default = { };
      example = {
        "myhost" = "http://service.somewhere:1234";
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
      package = pkgs.nginxStable.override { openssl = pkgs.libressl; };

      clientMaxBodySize = "0"; # disable file upload limits

      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;

      # zstd causes CPU spikes on workers - bug in nginx?
      recommendedZstdSettings = false;

      # harden TLS
      recommendedTlsSettings = false; # OCSP stapling is PITA
      sslProtocols = "TLSv1.3";
      sslCiphers = null;
      commonHttpConfig = ''
        # Keep in sync with https://ssl-config.mozilla.org/#server=nginx&config=intermediate

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
              host = name;
              proxyPass = value;
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

    mySystemApps.letsencrypt.certsGroup = config.services.nginx.group;

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };

}
