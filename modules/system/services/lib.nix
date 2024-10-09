{
  config,
  pkgs,
  lib,
  ...
}:
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

    importYAML =
      file:
      builtins.fromJSON (
        builtins.readFile (
          pkgs.runCommandNoCC "converted-yaml.json" { } ''${lib.getExe pkgs.yj} < "${file}" > "$out"''
        )
      );
  };
}
