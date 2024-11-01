{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.audiobookshelf;
in
{
  options.mySystemApps.audiobookshelf = {
    enable = lib.mkEnableOption "audiobookshelf container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/audiobookshelf";
    };
    audiobooksPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing audiobooks.";
    };
    podcastsPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing podcasts.";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/audiobookshelf/env";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for audiobookshelf are disabled!") ];

    sops.secrets."${cfg.sopsSecretPrefix}/HOMEPAGE_API_KEY" = { };

    virtualisation.oci-containers.containers.audiobookshelf = svc.mkContainer {
      cfg = {
        image = "ghcr.io/advplyr/audiobookshelf:2.15.1@sha256:9096480cb2b8cbfb3da155ea3cea5e9bfd4f3c2aae6196225c5b26d31bad1a99";
        user = "65000:65000";
        environment = {
          PORT = "3000";
        };
        volumes = [
          "${cfg.dataDir}/config:/config"
          "${cfg.audiobooksPath}:/audiobooks"
          "${cfg.podcastsPath}:/podcasts"
          "/var/cache/audiobookshelf/metadata:/metadata"
        ];
      };
      opts = {
        # for fetching metadata
        allowPublic = true;
      };
    };

    mySystemApps.authelia.oidcClients = [
      {
        client_id = "audiobookshelf";
        client_name = "audiobookshelf";
        client_secret = "$pbkdf2-sha512$310000$COYPbh8tgyObJW6Dvqgm0w$MyA1TlJgfKGBOJRs/edyTdLgxXsI6yU8KbwNx06Gow95lK4KofkLRtVV5s3EYU6DtlqUJCNdsjjZYL4DstvHiw"; # unencrypted version in SOPS
        consent_mode = "implicit";
        public = false;
        authorization_policy = "two_factor";
        require_pkce = true;
        pkce_challenge_method = "S256";
        redirect_uris = [
          "https://audiobookshelf.${config.mySystem.rootDomain}/auth/openid/callback"
          "https://audiobookshelf.${config.mySystem.rootDomain}/auth/openid/mobile-redirect"
        ];
        scopes = [
          "email"
          "openid"
          "profile"
          "groups"
        ];
        userinfo_signed_response_alg = "none";
        token_endpoint_auth_method = "client_secret_basic";
      }
    ];

    services = {
      nginx.virtualHosts.audiobookshelf = svc.mkNginxVHost {
        host = "audiobookshelf";
        proxyPass = "http://audiobookshelf.docker:3000";
        autheliaIgnorePaths = [
          "/api"
          "/login"
          "/status"
        ];
        customCSP = ''
          default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data:
          mediastream: blob: wss: https://*.${config.mySystem.rootDomain};
          object-src 'none';
          img-src 'self' data: blob: https:;
        '';
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "audiobookshelf";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-audiobookshelf = {
      path = [ pkgs.iproute2 ];
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config" /var/cache/audiobookshelf/metadata
        chown 65000:65000 "${cfg.dataDir}/config" /var/cache/audiobookshelf/metadata
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Audiobookshelf = svc.mkHomepage "audiobookshelf" // {
        description = "Podcasts and audiobooks manager";
        widget = {
          type = "audiobookshelf";
          url = "http://audiobookshelf:3000";
          key = "@@AUDIOBOOKSHELF_API_KEY@@";
          fields = [
            "books"
            "booksDuration"
            "podcasts"
            "podcastsDuration"
          ];
        };
      };
      secrets.AUDIOBOOKSHELF_API_KEY =
        config.sops.secrets."${cfg.sopsSecretPrefix}/HOMEPAGE_API_KEY".path;
    };
  };
}
