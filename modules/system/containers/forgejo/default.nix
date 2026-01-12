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
      // lib.optionalAttrs cfg.enableRunner {
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
          image = "codeberg.org/forgejo/forgejo:13.0.4-rootless@sha256:5ebd7bb1f81fd9948e63d810ebd40830a00f8ca29165ca227105b3f5e4ec40bd";
          dependsOn = lib.optionals config.mySystemApps.minio.enable [ "minio" ];
          environment = {
            FORGEJO__actions__ENABLED = if cfg.enableRunner then "true" else "false";
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
      forgejo-dind = lib.mkIf cfg.enableRunner (
        svc.mkContainer {
          cfg = {
            dependsOn = [ "forgejo" ];
            cmd = [
              "dockerd"
              "-H"
              "tcp://0.0.0.0:2375"
              "--tls=false"
            ];
            image = "public.ecr.aws/docker/library/docker:dind@sha256:d95427251fd155cd69a03311a8c4edf6d0778595444afc2d2c800a156eb2ecac";
          };
          opts = {
            # to communicate with forgejo via its domain
            allowPublic = true;
            privileged = true;
          };
        }
      );
      forgejo-runner = lib.mkIf cfg.enableRunner (
        svc.mkContainer {
          cfg = {
            cmd = [
              "/bin/forgejo-runner"
              "-c"
              "/data/config.yaml"
              "daemon"
            ];
            dependsOn = [ "forgejo-dind" ];
            image = "data.forgejo.org/forgejo/runner:12.5.1@sha256:88830fccef884ac8af5f858122f4e057ebd2bd4f01079824fa8dbcf62a38290a";
            environment = {
              DOCKER_HOST = "tcp://forgejo-dind:2375";
            };
            volumes = [ "/var/cache/forgejo/runner:/data" ];
          };
          opts = {
            # to communicate with forgejo via its domain
            allowPublic = true;
            readOnlyRootFilesystem = false;
          };
        }
      );

    };

    services = {
      nginx.virtualHosts.forgejo = svc.mkNginxVHost {
        host = "git";
        proxyPass = "http://forgejo.docker:3000";
        autheliaIgnorePaths = [
          "~* ^/[^/]+/[^/]+/(info|git-upload-pack).*$"
          "/api"
        ];
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
          chown -R 1000:65000 "$(dirname ${
            config.sops.secrets."${cfg.sopsSecretPrefix}/${builtins.elemAt secretEnvs 0}".path
          })"
        '';
        postStart = lib.mkIf cfg.enableRunner (
          lib.mkAfter ''
            attempts=0
            until ${lib.getExe pkgs."${config.virtualisation.oci-containers.backend}"} exec forgejo \
            forgejo forgejo-cli actions register --name default --labels docker,python,self-hosted \
            --secret "$(cat ${
              config.sops.secrets."${cfg.sopsSecretPrefix}/FORGEJO_RUNNER_TOKEN".path
            })" || [ $attempts -ge 10 ]; do sleep 1; ((attempts++)) || true; done
          ''
        );
      };
      docker-forgejo-runner = lib.mkIf cfg.enableRunner {
        preStart = lib.mkAfter ''
          mkdir -p "/var/cache/forgejo/runner"
          echo -e 'runner:\n  labels: ["self-hosted:host",
          "docker:docker://public.ecr.aws/docker/library/node:lts",
          "python:docker://public.ecr.aws/docker/library/python:latest"]' > "/var/cache/forgejo/runner/config.yaml"
          chown 1000:1000 "/var/cache/forgejo/runner" "/var/cache/forgejo/runner/config.yaml"

          sleep 5
          ${lib.getExe pkgs."${config.virtualisation.oci-containers.backend}"} run \
          --rm -v /var/cache/forgejo/runner:/data --network public \
          ${config.virtualisation.oci-containers.containers.forgejo-runner.image} \
          forgejo-runner -c /data/config.yaml create-runner-file --instance https://git.${config.mySystem.rootDomain} \
          --secret "$(cat ${
            config.sops.secrets."${cfg.sopsSecretPrefix}/FORGEJO_RUNNER_TOKEN".path
          })" --connect
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
