{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.navidrome;
in
{
  options.mySystemApps.navidrome = {
    enable = lib.mkEnableOption "navidrome container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/navidrome";
    };
    musicPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing music.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for navidrome are disabled!") ];

    virtualisation.oci-containers.containers.navidrome = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/navidrome:0.54.4@sha256:e30b24d64dfa1b25804d2985faa0d9d2b965ac219aff6cf04aae7df3cb0bd33c";
        environment = {
          ND_BASEURL = "/";
          ND_COVERARTPRIORITY = "folder.*, cover.*, front.*";
          ND_DEFAULTLANGUAGE = "en";
          ND_ENABLEINSIGHTSCOLLECTOR = "false";
          ND_REVERSEPROXYUSERHEADER = "Remote-User";
          ND_REVERSEPROXYWHITELIST = "172.16.0.0/12";
          ND_SCANNER_GROUPALBUMRELEASES = "true";
        };
        volumes = [
          "${cfg.dataDir}/config:/config"
          "${cfg.musicPath}:/data:ro"
        ];
      };
      opts = {
        # online radios
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.navidrome = svc.mkNginxVHost {
        host = "navidrome";
        proxyPass = "http://navidrome.docker:3000";
        customCSP = ''
          default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline'
          data: mediastream: blob: wss: https://*.${config.mySystem.rootDomain};
          object-src 'none';
          img-src 'self' data: blob: https:;
          media-src 'self' data: blob: https:;
        '';
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "navidrome";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-navidrome = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Navidrome = svc.mkHomepage "navidrome" // {
        description = "Music collection manager and player";
      };
    };
  };
}
