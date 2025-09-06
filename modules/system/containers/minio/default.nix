{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.minio;
  secretEnvs = [
    "MINIO_ROOT_PASSWORD"
    "MINIO_ROOT_USER"
  ];
in
{
  options.mySystemApps.minio = {
    enable = lib.mkEnableOption "minio container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    buckets = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Bucket name";
            };
            backup = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Include bucket in backups";
            };
            public = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Make bucket publicly available";
            };
            owner = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Owner of the bucket, if not specified - it will default to root user.";
            };
          };
        }
      );
      default = [ ];
      example = [
        {
          name = "mybucket";
          backup = true;
          owner = "myowner";
        }
      ];
    };
    dataPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing S3 buckets.";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = ''
        Prefix for sops secret, under which all ENVs will be appended.
        For owner passwords use: MINIO_USER_ownername_PASSWORD (case matters!).
      '';
      default = "system/apps/minio/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for minio are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      secretEnvs =
        secretEnvs ++ (builtins.map (bucket: "MINIO_USER_${bucket.owner}_PASSWORD") cfg.buckets);

      containerName = "minio";
    };

    virtualisation.oci-containers.containers.minio = svc.mkContainer {
      cfg = {
        user = "65000:65000";
        # last good release of minio
        image = "quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z@sha256:a1ea29fa28355559ef137d71fc570e508a214ec84ff8083e39bc5428980b015e";
        cmd = [
          "server"
          "/data"
          "--console-address"
          ":9001"
        ];

        environment = {
          MINIO_BROWSER_REDIRECT_URL = "https://minio.${config.mySystem.rootDomain}";
          MINIO_UPDATE = "off";
        }
        // svc.mkContainerSecretsEnv { inherit secretEnvs; };

        volumes =
          svc.mkContainerSecretsVolumes {
            inherit (cfg) sopsSecretPrefix;
            inherit secretEnvs;
          }
          ++ [
            "${cfg.dataPath}:/data"
          ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
    };

    services = {
      nginx.virtualHosts = {
        minio = svc.mkNginxVHost {
          host = "minio";
          proxyPass = "http://minio.docker:9001";
          useAuthelia = false;
        };
        s3 = svc.mkNginxVHost {
          host = "s3";
          proxyPass = "http://minio.docker:9000";
          useAuthelia = false;
        };
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "minio";
          fullPaths = builtins.map (bucket: cfg.dataPath + "/" + bucket.name) (
            builtins.filter (bucket: bucket.backup) cfg.buckets
          );
        }
      );
    };

    systemd.services.docker-minio =
      let
        dockerBin = lib.getExe pkgs."${config.virtualisation.oci-containers.backend}";
      in
      {
        preStart = lib.mkAfter ''
          mkdir -p "${cfg.dataPath}"
          chown 65000:65000 "${cfg.dataPath}"
        '';
        postStart = lib.mkAfter (
          ''
            MINIO_ROOT_USER="$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/MINIO_ROOT_USER".path})"
            MINIO_ROOT_PASSWORD="$(cat ${
              config.sops.secrets."${cfg.sopsSecretPrefix}/MINIO_ROOT_PASSWORD".path
            })"

            MC_HOST_minio="http://$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD@127.0.0.1:9000"

            R=0
            until ${dockerBin} exec minio curl --max-time 1 -s http://127.0.0.1:9000; do
              R=$((R + 1))
              if [ "$R" -ge 30 ]; then
                exit 1
              fi
              sleep 1
            done
          ''
          + (lib.concatStringsSep "\n" (
            builtins.map (
              bucket:
              (
                ''
                  cat <<EOFDOCKER | ${dockerBin} exec -i -e MC_HOST_minio="$MC_HOST_minio" minio sh -
                  if mc stat minio/${bucket.name} > /dev/null 2>&1; then
                    exit 0
                  fi

                  mc mb minio/${bucket.name}
                ''
                + lib.optionalString (bucket.owner != null) ''
                  cat <<EOFPOLICY > /tmp/policy.json
                  {
                    "Version": "2012-10-17",
                    "Statement": [
                      {
                        "Sid": "BucketAccessForUser",
                        "Effect": "Allow",
                        "Action": [
                          "s3:*"
                        ],
                        "Resource": [
                          "arn:aws:s3:::${bucket.name}",
                          "arn:aws:s3:::${bucket.name}/*"
                        ]
                      }
                    ]
                  }
                  EOFPOLICY

                  mc admin policy create minio "${bucket.name}-rw" /tmp/policy.json
                  rm -f /tmp/policy.json

                  mc admin user add minio ${bucket.owner} "$(cat ${
                    config.sops.secrets."${cfg.sopsSecretPrefix}/MINIO_USER_${bucket.owner}_PASSWORD".path
                  })"
                  mc admin policy attach minio "${bucket.name}-rw" --user "${bucket.owner}"
                ''
                + lib.optionalString bucket.public ''
                  mc anonymous set download "minio/${bucket.name}"
                ''
              )
              + ''
                EOFDOCKER
              ''
            ) cfg.buckets
          ))
          + ''
            exit 0
          ''
        );
      };

    mySystemApps.homepage = {
      services.Apps.Minio = svc.mkHomepage "minio" // {
        description = "S3-compatible storage";
      };
    };
  };
}
