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
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
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
          TZ = config.mySystem.time.timeZone;
        };
      } cfg)
      // {
        dependsOn = [ "network-prepare" ] ++ (cfg.dependsOn or [ ]);
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
      {
        containerName,
        sopsSecretPrefix,
        secretEnvs,
      }:
      builtins.listToAttrs (
        builtins.map (env: {
          name = "${sopsSecretPrefix}/${env}";
          value = {
            group = config.users.groups.abc.name;
            mode = "0440";
            restartUnits = [ "docker-${containerName}.service" ];
          };
        }) secretEnvs
      );

    mkContainerSecretsEnv =
      {
        suffix ? "_FILE",
        secretEnvs,
      }:
      builtins.listToAttrs (
        builtins.map (env: {
          name = "${env}${suffix}";
          value = "/secrets/${env}";
        }) secretEnvs
      );

    mkContainerSecretsVolumes =
      { sopsSecretPrefix, secretEnvs }:
      builtins.map (
        env: "${config.sops.secrets."${sopsSecretPrefix}/${env}".path}:/secrets/${env}:ro"
      ) secretEnvs;

    mkRestic =
      {
        name,
        paths,
        excludePaths ? [ ],
      }:
      let
        timerConfig = {
          OnCalendar = "02:05";
          Persistent = true;
          RandomizedDelaySec = "3h";
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 10"
        ];
        initialize = true;
        backupPrepareCommand = ''
          # remove stale locks - this avoids some occasional annoyance
          #
          ${lib.getExe pkgs.restic} unlock --remove-all || true
        '';
        passwordFile = config.sops.secrets."${config.mySystem.backup.passFileSopsSecret}".path;

        # Move the path to the zfs snapshot path
        includePaths = map (path: "${config.mySystem.backup.snapshotMountPath}/${path}") paths;
      in
      {
        # local backup
        "${name}-local" = lib.mkIf config.mySystem.backup.local.enable {
          inherit
            pruneOpts
            timerConfig
            initialize
            backupPrepareCommand
            passwordFile
            ;

          paths = includePaths;
          exclude = excludePaths;
          repository = "${config.mySystem.backup.local.location}/${name}";
        };

        # remote backup
        "${name}-remote" = lib.mkIf config.mySystem.backup.remote.enable {
          inherit
            pruneOpts
            timerConfig
            initialize
            backupPrepareCommand
            passwordFile
            ;

          paths = includePaths;
          exclude = excludePaths;
          repositoryFile =
            config.sops.secrets."${config.mySystem.backup.remote.repositoryFileSopsSecret}".path;
        };
      };

    importYAML =
      file:
      builtins.fromJSON (
        builtins.readFile (
          pkgs.runCommandNoCC "converted-yaml.json" { } ''${lib.getExe pkgs.yj} < "${file}" > "$out"''
        )
      );

    templateFile =
      {
        name,
        src,
        vars,
      }:
      pkgs.stdenv.mkDerivation {
        name = "${name}";

        nativeBuildInpts = [ pkgs.mustache-go ];

        # Pass Json as file to avoid escaping
        passAsFile = [ "jsonData" ];
        jsonData = builtins.toJSON vars;

        # Disable phases which are not needed. In particular the unpackPhase will
        # fail, if no src attribute is set
        phases = [
          "buildPhase"
          "installPhase"
        ];

        buildPhase = ''
          ${pkgs.mustache-go}/bin/mustache $jsonDataPath ${src} > rendered_file
        '';

        installPhase = ''
          cp rendered_file $out
        '';
      };
  };
}
