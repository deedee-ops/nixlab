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
    sync.enable = lib.mkEnableOption "koreader sync container" // {
      default = !cfg.enable;
    };
  };

  config = lib.mkIf cfg.sync.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for koreader are disabled!") ];

    virtualisation.oci-containers.containers.koreader-sync = svc.mkContainer {
      cfg = {
        image = "koreader/kosync:1.0.1.3@sha256:5129931e8e5066a109d9baa23e3a9c3568e0fea284ca57c50e372b6434b0e827";
        ports = [ "8081:7200" ];
        volumes = [ "${cfg.dataDir}/sync:/var/lib/redis" ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/var/log/redis,tmpfs-mode=1777"
          "--mount"
          "type=tmpfs,destination=/app/koreader-sync-server/logs,tmpfs-mode=1777"
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--cap-add=CAP_FSETID"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
        ];
      };
      opts = {
        readOnlyRootFilesystem = false;
        # allow port to be available externally
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.koreader-sync = svc.mkNginxVHost {
        host = "koreader-sync";
        proxyPass = "https://koreader-sync.docker:7200";
        useAuthelia = false;
      };
    };

    systemd.services.docker-koreader-sync = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/sync"
        chown 65000:65000 "${cfg.dataDir}/sync"
      '';
    };

    networking.firewall.allowedTCPPorts = [ 8081 ];

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };
  };
}
