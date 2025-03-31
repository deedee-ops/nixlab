{
  config,
  pkgs,
  lib,
  ...
}:
{
  _module.args.svc = {
    mkHomepage = name: {
      icon = "${name}.svg";
      href = "https://${name}.${config.mySystem.rootDomain}";
      server = "deedee";
      container = name;
    };
    mkNginxVHost =
      {
        host,
        proxyPass,
        useACMEHost ? "wildcard.${config.mySystem.rootDomain}",
        useAuthelia ? config.mySystemApps.authelia.enable,
        useHostAsServerName ? false,
        autheliaIgnorePaths ? [ ],
        customCSP ? null,
        extraConfig ? "",
      }:
      let
        # proxy_pass needs to be passed as variable, otherwise resolver won't work as expected
        baseConfig =
          extraConfig
          + ''

            set $host_to_pass ${proxyPass};
            proxy_pass $host_to_pass;

            proxy_set_header Host $host;
            proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
            proxy_set_header X-Forwarded-URI $request_uri;
            proxy_set_header X-Forwarded-Ssl on;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;
          ''
          + (lib.optionalString (customCSP != null) (
            if customCSP == "disable" then
              ''
                more_clear_headers "Content-Security-Policy";
              ''
            else
              ''
                more_set_headers "Content-Security-Policy: ${
                  lib.trim (builtins.replaceStrings [ "\n" ] [ " " ] customCSP)
                }";
              ''
          ));
      in
      {
        inherit useACMEHost;

        extraConfig =
          ''
            resolver 127.0.0.1:5533;
          ''
          + lib.optionalString useAuthelia ''
            set $upstream_authelia http://authelia.docker:9091/api/authz/auth-request;

            ## Virtual endpoint created by nginx to forward auth requests.
            location /internal/authelia/authz {
                ## Essential Proxy Configuration
                internal;
                proxy_pass $upstream_authelia;

                ## Headers
                ## The headers starting with X-* are required.
                proxy_set_header X-Original-Method $request_method;
                proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
                proxy_set_header X-Forwarded-For $remote_addr;
                proxy_set_header Content-Length "";
                proxy_set_header Connection "";

                ## Basic Proxy Configuration
                proxy_pass_request_body off;
                proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; # Timeout if the real server is dead
                proxy_redirect http:// $scheme://;
                proxy_http_version 1.1;
                proxy_cache_bypass $cookie_session;
                proxy_no_cache $cookie_session;
                proxy_buffers 4 32k;
                client_body_buffer_size 128k;

                ## Advanced Proxy Configuration
                send_timeout 5m;
                proxy_read_timeout 240;
                proxy_send_timeout 240;
                proxy_connect_timeout 240;
            }
          '';
        locations =
          {
            "/" = {
              proxyWebsockets = true;
              extraConfig =
                baseConfig
                + lib.optionalString useAuthelia ''
                  auth_request /internal/authelia/authz;
                  auth_request_set $user $upstream_http_remote_user;
                  auth_request_set $groups $upstream_http_remote_groups;
                  auth_request_set $name $upstream_http_remote_name;
                  auth_request_set $email $upstream_http_remote_email;
                  proxy_set_header Remote-User $user;
                  proxy_set_header Remote-Groups $groups;
                  proxy_set_header Remote-Email $email;
                  proxy_set_header Remote-Name $name;
                  auth_request_set $redirection_url $upstream_http_location;
                  error_page 401 =302 $redirection_url;
                '';
            };
          }
          // builtins.listToAttrs (
            builtins.map (location: {
              name = location;
              value = {
                proxyWebsockets = true;
                extraConfig = baseConfig;
              };
            }) autheliaIgnorePaths
          );

        serverName = if useHostAsServerName then host else "${host}.${config.mySystem.rootDomain}";
        forceSSL = true;
      };

    mkContainer =
      {
        cfg,
        opts ? { },
      }:
      let
        args = {
          allowPublic = false;
          enableGPU = false;
          readOnlyRootFilesystem = true;
          allowPrivilegeEscalation = false;
          routeThroughVPN = false;
          useHostNetwork = false;
          customNetworks = [ ];
        } // opts;
      in
      (lib.recursiveUpdate {
        autoStart = !config.mySystem.recoveryMode;
        environment = {
          TZ = config.mySystem.time.timeZone;
        };
      } cfg)
      // {
        dependsOn = (lib.optionals args.routeThroughVPN [ "gluetun" ]) ++ (cfg.dependsOn or [ ]);
        extraOptions =
          (lib.optionals args.readOnlyRootFilesystem [ "--read-only" ])
          ++ [
            "--cap-drop=all"
          ]
          ++ (lib.optionals args.enableGPU [
            "--device"
            "nvidia.com/gpu=all"
          ])
          ++ (lib.optionals (!args.allowPrivilegeEscalation) [ "--security-opt=no-new-privileges" ])
          ++ (cfg.extraOptions or [ ])
          ++ lib.optionals (!args.routeThroughVPN) [
            # /etc/hosts mapping conflicts with container network mode
            "--add-host=host.docker.internal:${config.mySystemApps.docker.network.private.hostIP}"
          ]
          ++ (
            if (builtins.length args.customNetworks > 0) then
              builtins.map (network: "--network=${network}") args.customNetworks
            else
              (
                if args.routeThroughVPN then
                  [ "--network=container:gluetun" ]
                else if args.useHostNetwork then
                  [ "--network=host" ]
                else
                  [
                    "--network=${config.mySystemApps.docker.network.private.name}"
                  ]
                  ++ lib.optionals args.allowPublic [
                    "--network=${config.mySystemApps.docker.network.public.name}"
                  ]
              )
          );
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
      {
        sopsSecretPrefix,
        secretEnvs,
        secretPath ? "/secrets",
      }:
      builtins.map (
        env: "${config.sops.secrets."${sopsSecretPrefix}/${env}".path}:${secretPath}/${env}:ro"
      ) secretEnvs;

    mkSecretEnvFile =
      {
        dest,
        sopsSecretPrefix,
        secretEnvs,
      }:
      ''
        echo -n > ${dest}
        chmod 600 ${dest}
      ''
      + builtins.concatStringsSep "\n" (
        builtins.map (
          env: "echo \"${env}=$(cat ${config.sops.secrets."${sopsSecretPrefix}/${env}".path})\" >> ${dest}"
        ) secretEnvs
      );

    mkRestic =
      {
        name,
        paths,
        fullPaths ? [ ],
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

        # Move the path to the zfs snapshot path
        includePaths =
          (map (path: "${config.mySystem.backup.snapshotMountPath}/${path}") paths) ++ fullPaths;
      in
      {
        # local backup
        "${name}-local" = lib.mkIf config.mySystem.backup.local.enable {
          inherit
            pruneOpts
            timerConfig
            initialize
            backupPrepareCommand
            ;

          paths = includePaths;
          exclude = excludePaths;
          passwordFile = config.sops.secrets."${config.mySystem.backup.local.passFileSopsSecret}".path;
          repository = "${config.mySystem.backup.local.location}/${name}";
        };

      }
      // builtins.listToAttrs (
        # remote backups
        builtins.map (remote: {
          name = "${name}-remote-${remote.name}";
          value = {
            inherit
              pruneOpts
              timerConfig
              initialize
              backupPrepareCommand
              ;

            paths = includePaths;
            exclude = excludePaths;
            passwordFile = config.sops.secrets."${remote.passFileSopsSecret}".path;
            repository = "${remote.location}/${name}";
            environmentFile = config.sops.secrets."${remote.envFileSopsSecret}".path;
          };
        }) config.mySystem.backup.remotes
      );
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
