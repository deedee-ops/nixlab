{ config, ... }:
{
  _module.args.svc = {
    mkNginxVHost = host: proxyPass: {
      locations."/" = {
        inherit proxyPass;

        proxyWebsockets = true;
      };

      useACMEHost = "wildcard.${config.mySystem.rootDomain}";
      serverName = "${host}.${config.mySystem.rootDomain}";
      forceSSL = true;
    };
  };
}
