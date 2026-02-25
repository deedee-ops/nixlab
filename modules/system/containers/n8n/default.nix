{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.n8n;
  secretEnvs = [
    "N8N_LICENSE_ACTIVATION_KEY"
    "N8N_ENTRYPOINT_PATCHES"
  ];
in
{
  options.mySystemApps.n8n = {
    enable = lib.mkEnableOption "n8n container";
    enablePatches = lib.mkEnableOption "n8n container improvements" // {
      default = true;
    };
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/n8n";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/n8n/env";
    };
    integrations = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "grist"
          "paperless-ngx"
          "stirlingpdf"
          "syncthing"
        ]
      );
      description = "List of modules n8n should integrate to.";
      default = [ ];
    };
    consumeDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of directories, n8n will be monitoring in the workflows.";
      default = [ ];
    };
    targetPaths = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = ''
        List of directories, n8n will be writing data to.
        Key is is path under `/target` in n8n host, value is path on host.
      '';
      default = { };
      example = {
        "receipts" = "/tank/receipts";
      };
    };
  };

  config =
    let
      image = "docker.n8n.io/n8nio/n8n:stable@sha256:fdf1e22bc04a03e38da41da5a56ba9b9a48510f480874290ea9c180844cbdb0c";
    in
    lib.mkIf cfg.enable {
      warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for n8n are disabled!") ];

      assertions = [
        {
          assertion = builtins.all (
            integration: config.mySystemApps."${integration}".enable
          ) cfg.integrations;
          message = "One of the enabled n8n integrations is not set up.";
        }
      ];

      sops.secrets = svc.mkContainerSecretsSops {
        inherit (cfg) sopsSecretPrefix;
        inherit secretEnvs;

        containerName = "n8n";
      };

      virtualisation.oci-containers.containers.n8n = svc.mkContainer {
        cfg = {
          dependsOn = cfg.integrations;
          user = "1000:1000";
          image = if cfg.enablePatches then "n8n" else image;
          environment = {
            GENERIC_TIMEZONE = config.mySystem.time.timeZone;
            N8N_EDITOR_BASE_URL = "https://n8n.${config.mySystem.rootDomain}";
            N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "false";
            N8N_LISTEN_ADDRESS = "0.0.0.0";
            N8N_RUNNERS_ENABLED = "true";
            WEBHOOK_URL = "https://n8n.${config.mySystem.rootDomain}";

            N8N_FORWARD_AUTH_HEADER = "Remote-Email";

            # email
            N8N_EMAIL_MODE = "smtp";
            N8N_SMTP_HOST = "maddy";
            N8N_SMTP_PORT = "25";
            N8N_SMTP_SENDER = config.mySystem.notificationSender;
            N8N_SMTP_SSL = "false";

            # telemetry
            N8N_DIAGNOSTICS_ENABLED = "false";
            N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
            N8N_TEMPLATES_ENABLED = "false";
          }
          // lib.optionalAttrs cfg.enablePatches {
            pull = "never";
          }
          // svc.mkContainerSecretsEnv { inherit secretEnvs; };
          volumes =
            svc.mkContainerSecretsVolumes {
              inherit (cfg) sopsSecretPrefix;
              inherit secretEnvs;
            }
            ++ [
              "${cfg.dataDir}/n8n:/home/node/.n8n"
              "${cfg.dataDir}/npm:/home/node/.npm"
            ]
            ++ (lib.optionals (builtins.elem "syncthing" cfg.integrations) [
              "${cfg.dataDir}/consume:/consume"
            ])
            ++ (builtins.map (
              targetPath: "${builtins.getAttr targetPath cfg.targetPaths}:/target/${targetPath}"
            ) (builtins.attrNames cfg.targetPaths));
          extraOptions = [
            "--mount"
            "type=tmpfs,destination=/home/node/.cache,tmpfs-mode=1777"
            "--mount"
            "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
          ];
        };
        opts = {
          # access to external services n8n uses for automations
          allowPublic = true;
        };
      };

      systemd.services.docker-n8n = {
        preStart =
          let
            dockerBin = lib.getExe pkgs."${config.virtualisation.oci-containers.backend}";
          in
          lib.mkAfter (
            (lib.optionalString cfg.enablePatches ''
              ${lib.getExe pkgs.bash} "${
                config.sops.secrets."${cfg.sopsSecretPrefix}/N8N_ENTRYPOINT_PATCHES".path
              }" ${dockerBin} ${image}
            '')
            + ''
              mkdir -p "${cfg.dataDir}/n8n" "${cfg.dataDir}/npm" "${cfg.dataDir}/consume"
              chown 1000:1000 "${cfg.dataDir}" "${cfg.dataDir}/n8n" "${cfg.dataDir}/npm" "${cfg.dataDir}/consume"
              chown 1000:1000 ${
                builtins.concatStringsSep " " (
                  builtins.map (env: config.sops.secrets."${cfg.sopsSecretPrefix}/${env}".path) secretEnvs
                )
              }
            ''
            + (builtins.concatStringsSep "\n" (
              builtins.map (consumeDir: "mkdir -p \"${cfg.dataDir}/consume/${consumeDir}\"") cfg.consumeDirs
            ))
            + ''

              chmod -R a+rwX "${cfg.dataDir}/consume"
            ''
          );
      };

      environment.persistence."${config.mySystem.impermanence.persistPath}" =
        lib.mkIf config.mySystem.impermanence.enable
          { directories = [ cfg.dataDir ]; };

      services = {
        nginx.virtualHosts.n8n = svc.mkNginxVHost {
          host = "n8n";
          proxyPass = "http://n8n.docker:5678";
          useAuthelia = true;
        };

        restic.backups = lib.mkIf cfg.backup (
          svc.mkRestic {
            name = "n8n";
            paths = [ cfg.dataDir ];
          }
        );
      };

      mySystemApps = {
        authelia.oidcClients = [
          {
            client_id = "n8n";
            client_name = "n8n";
            client_secret = "$pbkdf2-sha512$310000$giYGSLs3qt.IIHfFeR0NIA$rqwQ/1UkgkyNKg4uO0lPZy5hjPKUuPvezgXMlIWxHQEl23RFMcRur7JGdRCHxcotxiBjA2yp6BAwWlpdpKu8IQ"; # unencrypted version in SOPS
            consent_mode = "implicit";
            public = false;
            authorization_policy = "two_factor";
            redirect_uris = [
              "https://n8n.${config.mySystem.rootDomain}/rest/sso/oidc/callback"
            ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_post";
          }
        ];

        homepage = {
          services.Apps.N8N = svc.mkHomepage "n8n" // {
            description = "Automate everything";
          };
        };
        syncthing.extraPaths = lib.optionalAttrs (builtins.elem "syncthing" cfg.integrations) {
          "n8n/consume" = {
            dest = "${cfg.dataDir}/consume";
          };
        };
      };
    };
}
