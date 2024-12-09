{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.home-assistant;
in
{
  options.mySystemApps.home-assistant = {
    enable = lib.mkEnableOption "home-assistant container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/home-assistant";
    };
    envFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing redlib envs.";
      default = "system/apps/home-assistant/envfile";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for home-assistant are disabled!") ];

    sops.secrets."${cfg.envFileSopsSecret}" = { };

    virtualisation.oci-containers.containers.home-assistant = svc.mkContainer {
      cfg = {
        image = "ghcr.io/onedr0p/home-assistant:2024.12.2@sha256:352d00833a6bb2a1a82e20e846c054bccb4a186c7f264d06b139ca406af288e1";
        user = "65000:65000";
        environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
        volumes = [ "${cfg.dataDir}/config:/config" ];
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/config/logs,tmpfs-mode=1777"
          "--mount"
          "type=tmpfs,destination=/config/tts,tmpfs-mode=1777"
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
      opts = {
        # for various APIs
        allowPublic = true;
      };
    };

    services = {
      nginx.virtualHosts.home-assistant = svc.mkNginxVHost {
        host = "home";
        proxyPass = "http://home-assistant.docker:8123";
        useAuthelia = false;
        customCSP = "disable";
      };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "home-assistant";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-home-assistant = {
      preStart = lib.mkAfter ''
        mkdir -p "${cfg.dataDir}/config"
        chown 65000:65000 "${cfg.dataDir}/config"
      '';
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.home-assistant = svc.mkHomepage "home-assistant" // {
        href = "https://home.${config.mySystem.rootDomain}";
        description = "Home automation.";
      };
    };
  };
}
