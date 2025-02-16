{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.jellyfin;
in
{
  options.mySystemApps.jellyfin = {
    enable = lib.mkEnableOption "jellyfin container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/jellyfin";
    };
    videoPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing movies and tv shows.";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/jellyfin/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for jellyfin are disabled!") ];

    sops.secrets."${cfg.sopsSecretPrefix}/HOMEPAGE_API_KEY" = { };

    virtualisation.oci-containers.containers.jellyfin = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/jellyfin:10.10.6@sha256:0d3b351775942b71044ebd3faa8547cca58e863b336f5a7cccf6913c3a2133b1";
        environment = {
          DOTNET_SYSTEM_IO_DISABLEFILELOCKING = "true";
        };
        ports = [ "8096:8096" ];
        volumes = [
          "${cfg.dataDir}/config:/config"
          "/var/cache/jellyfin/transcode:/transcode"
          "/var/cache/jellyfin/internal-ip:/secrets/JELLYFIN_PublishedServerUrl:ro" # hack to dynamically pass current machine IP to env
          "${cfg.videoPath}:/data/video"
        ];
        extraOptions = [
          "--device=/dev/dri"
          "--add-host=authelia.${config.mySystem.rootDomain}:${config.mySystemApps.docker.network.private.hostIP}"
        ];
      };
      opts = {
        # for fetching metadata
        allowPublic = true;
      };
    };

    mySystemApps.authelia.oidcClients = [
      {
        client_id = "jellyfin";
        client_name = "Jellyfin";
        client_secret = "$pbkdf2-sha512$310000$McvlFsYvH5nWq19jqAzQZQ$ced4oGa2gBlsHR6ZxkqyQt63oLMmoedCJHA/7K/42HiDWdp3Yo2M5DjnkG2uB69OQRtgfh2qeOMrUrd8APyrMA"; # unencrypted version in SOPS
        consent_mode = "implicit";
        public = false;
        authorization_policy = "two_factor";
        require_pkce = true;
        pkce_challenge_method = "S256";
        redirect_uris = [ "https://jellyfin.${config.mySystem.rootDomain}/sso/OID/redirect/authelia" ];
        scopes = [
          "openid"
          "profile"
          "groups"
        ];
        userinfo_signed_response_alg = "none";
        token_endpoint_auth_method = "client_secret_post";
      }
    ];

    services = {
      nginx.virtualHosts.jellyfin = svc.mkNginxVHost {
        host = "jellyfin";
        proxyPass = "http://jellyfin.docker:8096";
        useAuthelia = false;
        customCSP = ''
          default-src 'self' 'unsafe-inline' data: blob: wss:;
          img-src 'self' data: https://repo.jellyfin.org https://raw.githubusercontent.com;
          object-src 'none';
          style-src 'self' 'unsafe-inline' data: blob: *.${config.mySystem.rootDomain};
        '';
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "jellyfin";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-jellyfin = {
      path = [ pkgs.iproute2 ];
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config" /var/cache/jellyfin/transcode
        chown 65000:65000 "${cfg.dataDir}/config" /var/cache/jellyfin /var/cache/jellyfin/transcode
        ip -f inet addr show ${config.mySystem.networking.rootInterface} | grep -Po 'inet \K[\d.]+' > "/var/cache/jellyfin/internal-ip"
        chown 65000:65000 "/var/cache/jellyfin/internal-ip"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    networking.firewall.allowedTCPPorts = [ 8096 ];

    mySystemApps.homepage = {
      services.Media.Jellyfin = svc.mkHomepage "jellyfin" // {
        description = "Multimedia streaming library";
        widget = {
          type = "jellyfin";
          url = "http://jellyfin:8096";
          key = "@@JELLYFIN_API_KEY@@";
          enableBlocks = true;
          enableNowPlaying = false;
          enableUser = false;
          showEpisodeNumber = true;
          expandOneStreamToTwoRows = false;
          fields = [
            "movies"
            "series"
          ];
        };
      };
      secrets.JELLYFIN_API_KEY = config.sops.secrets."${cfg.sopsSecretPrefix}/HOMEPAGE_API_KEY".path;
    };
  };
}
