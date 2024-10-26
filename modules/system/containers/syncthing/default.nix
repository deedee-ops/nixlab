{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.syncthing;
  secretEnvs = [ "SYNCTHING_API_KEY" ];
in
{
  options.mySystemApps.syncthing = {
    enable = lib.mkEnableOption "syncthing container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/syncthing";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/syncthing/env";
    };
    extraPaths = lib.mkOption {
      type = lib.type.attrsOf lib.types.str;
      description = ''
        Extra paths to be mounted for syncthing. These paths WILL NOT be backed up.
        For example: `{ "my-nas" => "/mnt/nas" };` would bindmount `/mnt/nas` to `{dataDir}/external/my-nas`.
      '';
      example = {
        "my-nas" = "/mnt/nas";
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for syncthing are disabled!") ];

    sops.secrets = svc.mkContainerSecretsSops {
      inherit (cfg) sopsSecretPrefix;
      inherit secretEnvs;

      containerName = "piped-api";
    };

    virtualisation.oci-containers.containers.syncthing = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/syncthing:1.27.12@sha256:7c4374e7af5e18fbdea49ea2ecc059cbfd668bc858697271490420222e12dfda";
        volumes = [
          "${cfg.dataDir}/config:/config"
          "${cfg.dataDir}/data:/data"
        ];
        ports = [ "22000:22000" ];
      };
      opts = {
        # to expose port to host, public network must be used
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.syncthing = svc.mkNginxVHost {
        host = "syncthing";
        proxyPass = "http://syncthing.docker:8384";
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "syncthing";
          paths = [
            "${cfg.dataDir}/config"
            "${cfg.dataDir}/data"
          ];
        }
      );
    };

    systemd.services.docker-syncthing = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        mkdir -p "${cfg.dataDir}/data"
        if [ ! -e "${cfg.dataDir}/config/config.xml" ]; then
          sed "s,@@SYNCTHING_API_KEY@@,$(cat ${
            config.sops.secrets."${cfg.sopsSecretPrefix}/SYNCTHING_API_KEY".path
          }),g" ${./config.xml} > ${cfg.dataDir}/config/config.xml
        fi
        chown -R 65000:65000 "${cfg.dataDir}/config" "${cfg.dataDir}/data"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };
  };
}
