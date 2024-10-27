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
        image = "ghcr.io/deedee-ops/navidrome:0.53.3@sha256:9869852f68d4ed6b8dd9cfc751f3a3bd6b43b4d10fdbdeda2b44edc117c13434";
        environment = {
          ND_BASEURL = "/";
          ND_COVERARTPRIORITY = "folder.*, cover.*, front.*";
          ND_DEFAULTLANGUAGE = "en";
          ND_REVERSEPROXYUSERHEADER = "Remote-User";
          ND_REVERSEPROXYWHITELIST = "172.16.0.0/12";
          ND_SCANNER_GROUPALBUMRELEASES = "true";
        };
        volumes = [
          "${cfg.dataDir}/config:/config"
          "${cfg.musicPath}:/data:ro"
        ];
      };
    };

    services = {
      nginx.virtualHosts.navidrome = svc.mkNginxVHost {
        host = "navidrome";
        proxyPass = "http://navidrome.docker:3000";
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
  };
}
