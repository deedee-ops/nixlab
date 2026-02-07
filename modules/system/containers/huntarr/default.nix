{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.huntarr;
in
{
  options.mySystemApps.huntarr = {
    enable = lib.mkEnableOption "huntarr container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/huntarr";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for huntarr are disabled!") ];

    virtualisation.oci-containers.containers.huntarr = svc.mkContainer {
      cfg = {
        image = "ghcr.io/plexguide/huntarr:9.2.3@sha256:b6858585104640cf029b669a30e6a0900465cb04b2815a5c3109ca1f47f24866";
        user = "65000:65000";
        volumes = [
          "${cfg.dataDir}/config:/config"
        ];
      };
    };

    services = {
      nginx.virtualHosts.huntarr = svc.mkNginxVHost {
        host = "huntarr";
        proxyPass = "http://huntarr.docker:9705";
        customCSP = ''
          default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data:
          mediastream: blob: wss: https://avatars.githubusercontent.com https://cdnjs.cloudflare.com;
          object-src 'none'; connect-src 'self' https://api.github.com;
        '';
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "huntarr";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-huntarr = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Media.Huntarr = svc.mkHomepage "huntarr" // {
        icon = "huntarr.png";
        description = "Old media assets sync";
      };
    };
  };
}
