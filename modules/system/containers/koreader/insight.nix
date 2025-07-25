{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.koreader;
in
{
  options.mySystemApps.koreader = {
    insight.enable = lib.mkEnableOption "koinsight container" // {
      default = cfg.enable;
    };
    insight.exposePort = lib.mkEnableOption "application port direct access";
  };

  config = lib.mkIf (cfg.enable && cfg.insight.enable) {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for koreader are disabled!") ];

    virtualisation.oci-containers.containers.koinsight = svc.mkContainer {
      cfg = {
        user = "65000:65000";
        image = "ghcr.io/georgesg/koinsight:v0.1.2@sha256:4ce89a18c0440a767254cd1a414b0a2dc612f9c2689fa58c59e6045b96c9afd0";
        environment = {
          HOSTNAME = "0.0.0.0";
        };
        ports = lib.optionals cfg.insight.exposePort [ "8082:3000" ];
        volumes = [ "${cfg.dataDir}/insight:/app/data" ];
      };
      opts = {
        # allow port to be available externally
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.koinsight = svc.mkNginxVHost {
        host = "koinsight";
        proxyPass = "http://koinsight.docker:3000";
        autheliaIgnorePaths = [
          "/api"
          "/users"
          "/syncs"
        ];
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "koreader";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-koinsight = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/insight"
        chown 65000:65000 "${cfg.dataDir}/insight"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    networking.firewall.allowedTCPPorts = [ 8082 ];

    mySystemApps.homepage = {
      services.Apps.KoInsight = svc.mkHomepage "koinsight" // {
        icon = "ko-insight.svg";
        description = "KoReader statistics";
      };
    };
  };
}
