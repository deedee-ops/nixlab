{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.calibre-web-automated;
in
{
  options.mySystemApps.calibre-web-automated = {
    enable = lib.mkEnableOption "calibre-web-automated container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/calibre-web-automated";
    };
    booksPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing books.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for calibre-web-automated are disabled!") ];

    virtualisation.oci-containers.containers.calibre-web-automated = svc.mkContainer {
      cfg = {
        image = "crocodilestick/calibre-web-automated:V3.0.4@sha256:bdf3dbf10be5a22cea09dd05f4d9ac4e7bdba4c411fef3e15c512ca723ee393d";
        environment = {
          PUID = "65000";
          PGID = "65000";
        };
        ports = [ "8083:8083" ];
        volumes = [
          "${./patch-cbz.sh}:/custom-cont-init.d/patch-cbz.sh"
          "${cfg.dataDir}/config:/config"
          "${cfg.dataDir}/cwa-book-ingest:/cwa-book-ingest"
          "${cfg.booksPath}:/calibre-library"
        ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--cap-add=CAP_FSETID"
          "--cap-add=CAP_KILL"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
          "--cap-add=CAP_SYS_CHROOT"
        ];
      };
      opts = {
        # download metadata
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.calibre-web-automated = svc.mkNginxVHost {
        host = "calibre-web";
        proxyPass = "http://calibre-web-automated.docker:8083";
        customCSP = "disable";
        autheliaIgnorePaths = [ "/opds" ];
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "calibre-web-automated";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-calibre-web-automated = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config" "${cfg.dataDir}/cwa-book-ingest"
        chown 65000:65000 "${cfg.dataDir}/config" "${cfg.dataDir}/cwa-book-ingest"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    networking.firewall.allowedTCPPorts = [ 8083 ];

    mySystemApps = {
      syncthing.extraPaths = {
        "calibre-web-automated/consume" = {
          dest = "${cfg.dataDir}/cwa-book-ingest";
        };
      };

      homepage = {
        services.Apps."Calibre Web" = svc.mkHomepage "calibre-web" // {
          description = "Books manager";
        };
      };
    };
  };
}
