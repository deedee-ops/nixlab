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
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      package = pkgs.nginxStable.override { openssl = pkgs.libressl; };

      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedZstdSettings = true;

      # harden TLS
      recommendedTlsSettings = true;
      sslProtocols = "TLSv1.3";
      sslCiphers = null;

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

        # Disable embedding as a frame
        more_set_headers "X-Frame-Options: DENY";

        # Minimize information leaked to other domains
        more_set_headers "Referrer-Policy: origin-when-cross-origin";
      '';

      virtualHosts = builtins.mapAttrs (name: value: svc.mkNginxVHost name value) cfg.extraVHosts;
    };

    mySystemApps.letsencrypt.certsGroup = config.services.nginx.group;

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };

}
