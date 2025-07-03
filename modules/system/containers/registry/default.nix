{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.registry;
in
{
  options.mySystemApps.registry = {
    enable = lib.mkEnableOption "registry container";
    enableUI = lib.mkEnableOption "registry UI container";
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing registry envs.";
      default = "system/apps/registry/envfile";
    };
    s3 = lib.mkOption {
      type = lib.types.submodule {
        options = {
          endpoint = lib.mkOption {
            type = lib.types.str;
            default = "http://minio:9000";
          };
          region = lib.mkOption {
            type = lib.types.str;
            default = "us-east-1";
          };
          bucket = lib.mkOption {
            type = lib.types.str;
            default = "registry";
          };
          encrypt = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          secure = lib.mkOption {
            type = lib.types.bool;
            default = !config.mySystemApps.minio.enable;
          };
        };
      };
      default = {
        endpoint = "http://minio:9000";
        region = "us-east-1";
        bucket = "registry";
        encrypt = false;
        secure = !config.mySystemApps.minio.enable;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers = {
      registry = svc.mkContainer {
        cfg = {
          image = "public.ecr.aws/docker/library/registry:3.0.0@sha256:1fc7de654f2ac1247f0b67e8a459e273b0993be7d2beda1f3f56fbf1001ed3e7";
          user = "65000:65000";
          environment = {
            OTEL_TRACES_EXPORTER = "none";
            REGISTRY_LOG_LEVEL = "info";
            REGISTRY_STORAGE = "s3";
            REGISTRY_STORAGE_REDIRECT_DISABLE = "true"; # solve "blob not found" errors, when using internal minio
            REGISTRY_STORAGE_S3_BUCKET = cfg.s3.bucket;
            REGISTRY_STORAGE_S3_CHUNKSIZE = "5242880";
            REGISTRY_STORAGE_S3_ENCRYPT = if cfg.s3.encrypt then "true" else "false";
            REGISTRY_STORAGE_S3_FORCEPATHSTYLE = "true";
            REGISTRY_STORAGE_S3_REGION = cfg.s3.region;
            REGISTRY_STORAGE_S3_REGIONENDPOINT = cfg.s3.endpoint;
            REGISTRY_STORAGE_S3_ROOTDIRECTORY = "/";
            REGISTRY_STORAGE_S3_SECURE = if cfg.s3.secure then "true" else "false";
            REGISTRY_STORAGE_S3_V4AUTH = "true";
          };
          environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
        };
        opts = {
          # access S3
          allowPublic = !config.mySystemApps.minio.enable;
        };
      };

      registry-ui = lib.mkIf cfg.enableUI (
        svc.mkContainer {
          cfg = {
            image = "joxit/docker-registry-ui:2.5.7@sha256:5594b76bf8dd9de479648e28f38572d020d260568be40b7e52b9758b442275e1";
            user = "101:101";
            environment = {
              CATALOG_ELEMENTS_LIMIT = "1000";
              CATALOG_MAX_BRANCHES = "1";
              CATALOG_MIN_BRANCHES = "1";
              DELETE_IMAGES = "true";
              NGINX_PROXY_PASS_URL = "http://registry:5000";
              REGISTRY_SECURED = "false";
              REGISTRY_TITLE = "Docker Registry UI";
              SHOW_CATALOG_NB_TAGS = "true";
              SHOW_CONTENT_DIGEST = "true";
              SINGLE_REGISTRY = "true";
              TAGLIST_PAGE_SIZE = "100";
            };
          };
          opts = {
            readOnlyRootFilesystem = false;
          };
        }
      );
    };

    services.nginx.virtualHosts.registry =
      let
        baseConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $http_host;
          proxy_set_header X-Forwarded-URI $request_uri;
          proxy_set_header X-Forwarded-Ssl on;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Real-IP $remote_addr;
        '';
      in
      rec {
        serverName = "registry.${config.mySystem.rootDomain}";
        forceSSL = true;
        addSSL = false;
        useACMEHost = "wildcard.${config.mySystem.rootDomain}";

        extraConfig = ''
          resolver 127.0.0.1:5533;

          ssl_certificate "${config.security.acme.certs."rsa-${useACMEHost}".directory}/fullchain.pem";
          ssl_certificate_key "${config.security.acme.certs."rsa-${useACMEHost}".directory}/key.pem";

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
        locations = {
          "/" = {
            proxyWebsockets = true;
            extraConfig =
              ''
                set $host_to_pass http://registry-ui.docker:8080;
                proxy_pass $host_to_pass;

              ''
              + baseConfig
              + ''
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
          "~* ^/v2.*$" = {
            extraConfig =
              ''
                set $host_to_pass http://registry.docker:5000;
                proxy_pass $host_to_pass;
              ''
              + baseConfig;
          };
        };
      };

    mySystemApps.homepage = {
      services.Apps.Registry = svc.mkHomepage "registry" // {
        icon = "docker.svg";
        description = "Docker registry";
      };
    };
  };
}
