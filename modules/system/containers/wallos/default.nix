{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.wallos;
in
{
  options.mySystemApps.wallos = {
    enable = lib.mkEnableOption "wallos container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/wallos";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for wallos are disabled!") ];

    virtualisation.oci-containers.containers.wallos = svc.mkContainer {
      cfg = {
        image = "ghcr.io/ellite/wallos:4.6.1@sha256:46f25daeebedbe00f409abdc82f07d1bde6818dc9fee8b360b0b09c453c4b999";
        volumes = [
          "${cfg.dataDir}/config:/var/www/html/db"
          "${cfg.dataDir}/data:/var/www/html/images/uploads"
          "${./nginx.conf}:/etc/nginx/nginx.conf:ro"
        ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--cap-add=CAP_NET_BIND_SERVICE"
        ];
      };
      opts = {
        # fetching logos
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.wallos = svc.mkNginxVHost {
        host = "wallos";
        proxyPass = "http://wallos.docker:80";
        customCSP = ''
          default-src 'self' 'unsafe-eval' 'wasm-unsafe-eval' 'unsafe-inline' data:
          mediastream: blob: wss: https://*.${config.mySystem.rootDomain};
          object-src 'none';
          img-src 'self' data: blob: https:;
        '';
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "wallos";
          paths = [ cfg.dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.Wallos = svc.mkHomepage "wallos" // {
        icon = "wallos.png";
        description = "Subscriptions manager";
      };
    };
  };
}
