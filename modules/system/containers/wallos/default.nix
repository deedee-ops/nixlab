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
        image = "ghcr.io/deedee-ops/wallos:2.41.0@sha256:0fabd98dceb3895f4dbaee1c62de6d031c81d69be87b38213bddb634fe2523ea";
        volumes = [
          "${cfg.dataDir}/config:/config"
          "${cfg.dataDir}/data:/data"
        ];
      };
      opts = {
        # fetching logos
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.wallos = svc.mkNginxVHost {
        host = "wallos";
        proxyPass = "http://wallos.docker:9000";
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

    systemd.services.docker-wallos = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config" "${cfg.dataDir}/data"
        chown 65000:65000 "${cfg.dataDir}/config" "${cfg.dataDir}/data"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.wallos = svc.mkHomepage "wallos" // {
        icon = "wallos.png";
        description = "Subscriptions manager";
      };
    };
  };
}
