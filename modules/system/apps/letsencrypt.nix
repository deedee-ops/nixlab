{ config, lib, ... }:
let
  cfg = config.mySystemApps.letsencrypt;
in
{
  options.mySystemApps.letsencrypt = {
    enable = lib.mkEnableOption "letsencrypt lego app";
    useProduction = lib.mkEnableOption "Use production servers.";
    cloudflareEnvironmentFile = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflare environment credentials for LEGO.";
    };
    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of domains (including wildcards) to issue LE certificates.";
    };
    certsGroup = lib.mkOption {
      type = lib.types.str;
      description = "Group owner of the generated certificates.";
      default = config.security.acme.defaults.group;
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults =
        {
          email = config.mySystem.notificationEmail;
          dnsResolver = "1.1.1.1:53";
        }
        // lib.optionalAttrs (!cfg.useProduction) {
          server = "https://acme-staging-v02.api.letsencrypt.org/directory";
        };
      certs = builtins.listToAttrs (
        builtins.map (domain: {
          name = builtins.replaceStrings [ "*" ] [ "wildcard" ] domain;
          value = {
            inherit domain;

            group = cfg.certsGroup;
            dnsProvider = "cloudflare";
            environmentFile = cfg.cloudflareEnvironmentFile;
          };
        }) cfg.domains
      );
    };
  };
}
