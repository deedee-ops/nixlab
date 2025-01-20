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

    virtualisation.oci-containers.containers = {
      code-server = svc.mkContainer {
        cfg = {
          image = "ghcr.io/coder/code-server:4.96.4@sha256:f93810f7f6636b3af3b1a750faf612349cddb89fbb6d28d69123a214fc75ee9e";
          user = "65000:65000";
          cmd = [
            "--auth"
            "none"
            "--user-data-dir"
            "/config/.vscode"
            "--extensions-dir"
            "/config/.vscode"
            "--port"
            "12321"
            "/config"
          ];
          volumes = [ "${cfg.dataDir}/config:/config" ];
          extraOptions = [
            "--mount"
            "type=tmpfs,destination=/home/coder,tmpfs-mode=1777"
          ];
        };
        opts = {
          # download extensions
          allowPublic = true;
          readOnlyRootFilesystem = false;
          allowPrivilegeEscalation = true;
        };
      };
      home-assistant = svc.mkContainer {
        cfg = {
          image = "ghcr.io/onedr0p/home-assistant:2025.1.2@sha256:7103698ead18144a39ae5412467fe1885331367aeb22a9c2046640f0c8f84cf7";
          user = "65000:65000";
          environmentFiles = [ config.sops.secrets."${cfg.envFileSopsSecret}".path ];
          environment = {
            HOME_ASSISTANT__HACS_INSTALL = "true";
          };
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
    };

    services = {
      nginx.virtualHosts = {
        code-server = svc.mkNginxVHost {
          host = "home-code";
          proxyPass = "http://code-server.docker:12321";
          useAuthelia = false;
          customCSP = "disable";
        };
        home-assistant = svc.mkNginxVHost {
          host = "home";
          proxyPass = "http://home-assistant.docker:8123";
          useAuthelia = false;
          customCSP = "disable";
        };
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
      services.Apps = {
        code-server = svc.mkHomepage "hass-code-server" // {
          icon = "coder.svg";
          href = "https://home-code.${config.mySystem.rootDomain}";
          description = "Home automation configuration editor.";
        };
        home-assistant = svc.mkHomepage "home-assistant" // {
          href = "https://home.${config.mySystem.rootDomain}";
          description = "Home automation.";
        };
      };
    };
  };
}
