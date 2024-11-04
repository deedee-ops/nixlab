{ config, lib, ... }:
let
  cfg = config.mySystemApps.ddclient;
in
{
  options.mySystemApps.ddclient = {
    enable = lib.mkEnableOption "ddclient app";
    cloudflareTokenSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing cloudflare token.";
      default = "system/apps/ddclient/cloudflare_token";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.cloudflareTokenSopsSecret}" = {
      restartUnits = [ "ddclient.service" ];
    };

    services.ddclient = {
      enable = true;
      ssl = true;
      usev4 = "webv4, webv4=https://cloudflare.com/cdn-cgi/trace, webv4-skip='ip='";
      usev6 = "disabled";
      protocol = "cloudflare";
      zone = "${config.mySystem.rootDomain}";
      extraConfig = "ttl=1";
      domains = [ "homelab.${config.mySystem.rootDomain}" ];
      username = "token";
      passwordFile = config.sops.secrets."${cfg.cloudflareTokenSopsSecret}".path;
    };
  };
}
