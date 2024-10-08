{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.nginx;
in
{
  options.mySystemApps.nginx = {
    enable = lib.mkEnableOption "nginx";
    rootDomain = lib.mkOption {
      type = lib.types.string;
      description = "TLD of all vhost subdomains.";
    };
    defaultCSPHeader = lib.mkOption {
      type = lib.types.string;
      default = ''
        default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data: mediastream: blob: wss: https://*.${cfg.rootDomain};
        object-src 'none';
      '';
      description = "Default CSP header for all VHosts (can be overriden per vhost).";
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
        add_header Strict-Transport-Security $hsts_header;

        # Enable CSP for your services.
        add_header Content-Security-Policy "${
          lib.trim (builtins.replaceStrings [ "\n" ] [ " " ] cfg.defaultCSPHeader)
        }" always;

        # Prevent injection of code in other mime types (XSS Attacks)
        add_header X-Content-Type-Options nosniff;

        # Disable embedding as a frame
        add_header X-Frame-Options DENY;

        # Minimize information leaked to other domains
        add_header 'Referrer-Policy' 'origin-when-cross-origin';
      '';
    };
  };
}
