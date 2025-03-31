{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.forgejo;
  secretEnvs = [
    "FORGEJO__cache__HOST"
    "FORGEJO__database__PASSWD"
    "FORGEJO__oauth2__JWT_SECRET"
    "FORGEJO__queue__CONN_STR"
    "FORGEJO__security__INTERNAL_TOKEN"
    "FORGEJO__security__SECRET_KEY"
    "FORGEJO__server__LFS_JWT_SECRET"
    "FORGEJO__session__PROVIDER_CONFIG"
    "FORGEJO__storage__MINIO_ACCESS_KEY_ID"
    "FORGEJO__storage__MINIO_SECRET_ACCESS_KEY"
  ];
in
{
  options.mySystemApps.forgejo = {
    enable = lib.mkEnableOption "forgejo container";
    enableRunner = lib.mkEnableOption "forgejo runner";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/forgejo";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/forgejo/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for forgejo are disabled!") ];

    sops.secrets =
      svc.mkContainerSecretsSops {
        inherit (cfg) sopsSecretPrefix;
        inherit secretEnvs;

        containerName = "forgejo";
      }
      // lib.optionals cfg.enableRunner {
        "${cfg.sopsSecretPrefix}/FORGEJO_RUNNER_TOKEN" = { };
      };

    mySystemApps.postgresql.userDatabases = [
      {
        username = "forgejo";
        passwordFile = config.sops.secrets."${cfg.sopsSecretPrefix}/FORGEJO__database__PASSWD".path;
        databases = [ "forgejo" ];
      }
    ];

    virtualisation.oci-containers.containers = {
      forgejo = svc.mkContainer {
        cfg = {
          image = "codeberg.org/forgejo/forgejo:10.0.3-rootless@sha256:5658d26e908b9acb533f86616000dd3d9619085e6979aa394d89142ed69f19b2";
          environment =
            {
              FORGEJO__server__DOMAIN = "git.${config.mySystem.rootDomain}";
              FORGEJO__server__SSH_DOMAIN = "git.${config.mySystem.rootDomain}";
              FORGEJO__server__ROOT_URL = "https://git.${config.mySystem.rootDomain}";
              FORGEJO__mailer__FROM = config.mySystem.notificationSender;
              FORGEJO__storage__MINIO_ENDPOINT = "s3.${config.mySystem.rootDomain}";
              FORGEJO__time__DEFAULT_UI_LOCATION = config.mySystem.time.timeZone;
            }
            // svc.mkContainerSecretsEnv {
              inherit secretEnvs;
              suffix = "__FILE";
            };
          ports = [ "2222:2222" ];
          volumes =
            svc.mkContainerSecretsVolumes {
              inherit (cfg) sopsSecretPrefix;
              inherit secretEnvs;
            }
            ++ [ "${cfg.dataDir}:/var/lib/gitea" ];
          extraOptions = [
            "--mount"
            "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
          ];
        };
        opts = {
          # to expose port to host, public network must be used
          allowPublic = true;
        };
      };
      forgejo-runner = lib.mkIf cfg.enableRunner (
        svc.mkContainer {
          cfg = {
            dependsOn = [
              "forgejo"
              "socket-proxy"
            ];
            image = "data.forgejo.org/forgejo/runner:6.3.1@sha256:5071e6832313bafe71577e05631bece88caff08fcfb372193e4a21941f4ed54b";
            environment = {
              DOCKER_HOST = "tcp://socket-proxy:2375";
            };
            volumes = [ "${cfg.dataDir}/runner:/data" ];
          };
        }
      );

    };

    services = {
      nginx.virtualHosts.forgejo = svc.mkNginxVHost {
        host = "git";
        proxyPass = "http://forgejo.docker:3000";
        autheliaIgnorePaths = [ "~* ^/[^/]+/[^/]+/info/lfs/.*$" ];
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "forgejo" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "forgejo";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services = {
      docker-forgejo = {
        path = [ pkgs.diffutils ];
        preStart = lib.mkAfter ''
          mkdir -p "${cfg.dataDir}/custom/conf"
          cp ${./app.ini} "${cfg.dataDir}/custom/conf/app.ini"
          chown 1000:1000 "${cfg.dataDir}" "${cfg.dataDir}/custom" "${cfg.dataDir}/custom/conf" "${cfg.dataDir}/custom/conf/app.ini"
          chmod 640 "${cfg.dataDir}/custom/conf/app.ini"

          # ugly hack to fix forgejo permissions, as sops-nix doesn't allow setting direct UID/GID yet
          chown -R 1000:1000 "$(dirname ${
            config.sops.secrets."${cfg.sopsSecretPrefix}/${builtins.elemAt secretEnvs 0}".path
          })"
        '';
        postStart = lib.mkAfter ''
          until ${lib.getExe pkgs."${config.virtualisation.oci-containers.backend}"} exec forgejo \
          forgejo forgejo-cli actions register --name default \
          --secret "${
            config.sops.secrets."${cfg.sopsSecretPrefix}/FORGEJO_RUNNER_TOKEN".path
          }"; do sleep 1; done
        '';
      };
      docker-forgejo-runner = lib.mkIf cfg.enableRunner {
        preStart = lib.mkAfter ''
          mkdir -p "${cfg.dataDir}/custom/runner"
          chown 1000:1000 "${cfg.dataDir}/runner"
        '';
        postStart = lib.mkAfter ''
          until ${lib.getExe pkgs."${config.virtualisation.oci-containers.backend}"} exec forgejo-runner \
          forgejo-runner create-runner-file --instance http://forgejo:3000 \
          --secret "${
            config.sops.secrets."${cfg.sopsSecretPrefix}/FORGEJO_RUNNER_TOKEN".path
          }"}; do sleep 1; done
        '';
      };
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    networking.firewall.allowedTCPPorts = [ 2222 ];

    mySystemApps.homepage = {
      services.Apps.Forgejo = svc.mkHomepage "forgejo" // {
        href = "https://git.${config.mySystem.rootDomain}";
        description = "Git repositories";
      };
    };
  };
}
