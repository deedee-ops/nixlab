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
        proxyWebsockets = true;
        # proxy_pass needs to be passed as variable, otherwise resolver won't work as expected
        extraConfig = ''
          resolver 127.0.0.1:5533;
          set $host_to_pass ${proxyPass};
          proxy_pass $host_to_pass;
        '';
      };

      useACMEHost = "wildcard.${config.mySystem.rootDomain}";
      serverName = "${host}.${config.mySystem.rootDomain}";
      forceSSL = true;
    };

    mkContainer =
      {
        cfg,
        opts ? {
          allowPublic = false;
        },
      }:
      (lib.recursiveUpdate {
        autoStart = true;
        environment = {
          TZ = "Europe/Warsaw";
        };
      } cfg)
      // {
        extraOptions =
          [
            "--read-only"
            "--cap-drop=all"
            "--security-opt=no-new-privileges"
            "--network=${config.mySystemApps.docker.network.private.name}"
            "--add-host=host.docker.internal:${config.mySystemApps.docker.network.private.hostIP}"
          ]
          ++ (cfg.extraOptions or [ ])
          ++ lib.optionals opts.allowPublic [ "--network=${config.mySystemApps.docker.network.public.name}" ];
      };

    mkContainerSecretsSops =
      containerName: secretPrefix: secretEnvs:
      builtins.listToAttrs (
        builtins.map (env: {
          name = "${secretPrefix}/${env}";
          value = {
            group = config.users.groups.abc.name;
            mode = "0440";
            restartUnits = [ "docker-${containerName}.service" ];
          };
        }) secretEnvs
      );

    mkContainerSecretsVolumes =
      secretPrefix: secretEnvs:
      builtins.map (
        env: "${config.sops.secrets."${secretPrefix}/${env}".path}:/secrets/${env}:ro"
      ) secretEnvs;

    importYAML =
      file:
      builtins.fromJSON (
        builtins.readFile (
          pkgs.runCommandNoCC "converted-yaml.json" { } ''${lib.getExe pkgs.yj} < "${file}" > "$out"''
        )
      );
  };
}
