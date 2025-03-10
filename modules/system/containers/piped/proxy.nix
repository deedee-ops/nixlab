{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.piped;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.piped-proxy = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/piped-proxy:latest@sha256:53a4e5e9085cc4f99c4b122ca78dfb5a5f9e32fb19cb5ea818a4ee25131183de";
        environment = {
          UDS = "1";
        };
        volumes = [ "/run/piped/socket:/app/socket" ];
      };
      opts = {
        # fetching YT tokens
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.piped-proxy =
        let
          ytproxy = ''
            proxy_buffering on;
            proxy_buffers 1024 16k;
            proxy_set_header X-Forwarded-For "";
            proxy_set_header CF-Connecting-IP "";
            proxy_hide_header "alt-svc";
            sendfile on;
            sendfile_max_chunk 512k;
            tcp_nopush on;
            aio threads=default;
            aio_write on;
            directio 16m;
            proxy_hide_header Cache-Control;
            proxy_hide_header etag;
            proxy_http_version 1.1;
            proxy_set_header Connection keep-alive;
            proxy_max_temp_file_size 32m;
            access_log off;
            proxy_pass http://unix:/run/piped/socket/actix.sock;
          '';
        in
        {
          useACMEHost = "wildcard.${config.mySystem.rootDomain}";
          serverName = "piped-proxy.${config.mySystem.rootDomain}";
          forceSSL = true;
          locations = {
            "~ (/videoplayback|/api/v4/|/api/manifest/)" = {
              extraConfig =
                ytproxy
                + ''
                  add_header Cache-Control private always;
                '';
            };
            "/" = {
              extraConfig =
                ytproxy
                + ''
                  add_header Cache-Control "public, max-age=604800";
                '';
            };
          };
        };
    };

    systemd.services.docker-piped-proxy = {
      preStart = lib.mkAfter ''
        mkdir -p /run/piped/socket
      '';
      postStart = lib.mkAfter ''
        while [ ! -e /run/piped/socket/actix.sock ]; do sleep 0.5; done
        chmod 777 /run/piped/socket/actix.sock
      '';
    };
  };
}
