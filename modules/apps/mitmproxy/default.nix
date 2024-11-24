{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.mitmproxy;
in
{
  options.myHomeApps.mitmproxy = {
    enable = lib.mkEnableOption "mitmproxy";
    caCertsSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing all mitmproxy ca certificate files.";
      default = "home/apps/mitmproxy/certs";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "${cfg.caCertsSopsSecret}/mitmproxy-ca-cert.cer" = { };
      "${cfg.caCertsSopsSecret}/mitmproxy-ca-cert.pem" = { };
      "${cfg.caCertsSopsSecret}/mitmproxy-ca.pem" = { };
      "${cfg.caCertsSopsSecret}/mitmproxy-dhparam.pem" = { };
      "${cfg.caCertsSopsSecret}/mitmproxy-ca-cert.p12-base64" = { };
      "${cfg.caCertsSopsSecret}/mitmproxy-ca.p12-base64" = { };
    };

    programs.firefox.policies.Certificates.Install = [
      config.sops.secrets."${cfg.caCertsSopsSecret}/mitmproxy-ca-cert.pem".path
    ];

    home = {
      shellAliases = {
        mitmproxy = "${lib.getExe' pkgs.mitmproxy "mitmproxy"} --set confdir=${config.xdg.configHome}/mitmproxy";
        mitmweb = "${lib.getExe' pkgs.mitmproxy "mitmweb"} --set confdir=${config.xdg.configHome}/mitmproxy";
      };

      packages = [
        pkgs.mitmproxy
      ];

      activation = {
        init-mitmproxy = lib.hm.dag.entryAfter [ "sopsNix" ] ''
          mkdir -p "${config.xdg.configHome}/mitmproxy"
          ln -sf "${
            config.sops.secrets."${cfg.caCertsSopsSecret}/mitmproxy-ca-cert.cer".path
          }" "${config.xdg.configHome}/mitmproxy/mitmproxy-ca-cert.cer"
          ln -sf "${
            config.sops.secrets."${cfg.caCertsSopsSecret}/mitmproxy-ca-cert.pem".path
          }" "${config.xdg.configHome}/mitmproxy/mitmproxy-ca-cert.pem"
          ln -sf "${
            config.sops.secrets."${cfg.caCertsSopsSecret}/mitmproxy-ca.pem".path
          }" "${config.xdg.configHome}/mitmproxy/mitmproxy-ca.pem"
          ln -sf "${
            config.sops.secrets."${cfg.caCertsSopsSecret}/mitmproxy-dhparam.pem".path
          }" "${config.xdg.configHome}/mitmproxy/mitmproxy-dhparam.pem"
          cat "${
            config.sops.secrets."${cfg.caCertsSopsSecret}/mitmproxy-ca-cert.p12-base64".path
          }" | base64 -d > "${config.xdg.configHome}/mitmproxy/mitmproxy-ca-cert.p12"
          cat "${
            config.sops.secrets."${cfg.caCertsSopsSecret}/mitmproxy-ca.p12-base64".path
          }" | base64 -d > "${config.xdg.configHome}/mitmproxy/mitmproxy-ca.p12"
        '';
      };
    };
  };
}
