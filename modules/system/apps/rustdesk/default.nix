{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.rustdesk;
  dataDir = "/var/lib/rustdesk";
in
{
  options.mySystemApps.rustdesk = {
    enable = lib.mkEnableOption "rustdesk app";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    relayHost = lib.mkOption {
      type = lib.types.str;
      description = "Relay Host advertised to the clients.";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, containing public and private key data.";
      default = "system/apps/rustdesk";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for rustdesk are disabled!") ];

    sops.secrets = {
      "${cfg.sopsSecretPrefix}/private_key" = {
        owner = "rustdesk";
        group = "rustdesk";
        restartUnits = [
          "rustdesk-signal.service"
          "rustdesk-relay.service"
        ];
      };
      "${cfg.sopsSecretPrefix}/public_key" = {
        owner = "rustdesk";
        group = "rustdesk";
        restartUnits = [
          "rustdesk-signal.service"
          "rustdesk-relay.service"
        ];
      };
    };

    services = {
      rustdesk-server = lib.mkIf (!config.mySystem.recoveryMode) {
        signal.relayHosts = [ cfg.relayHost ];

        enable = true;
        openFirewall = true;
      };

      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "rustdesk";
          paths = [ dataDir ];
        }
      );
    };

    system.activationScripts = lib.mkIf (!config.mySystem.impermanence.enable) {
      create-rustdesk-dir = {
        deps = [ "users" ];
        text = ''
          mkdir -p ${dataDir}

          cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/private_key".path} > ${dataDir}/id_ed25519
          cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/public_key".path} > ${dataDir}/id_ed25519.pub

          chown -R rustdesk:rustdesk ${dataDir}
          chmod 700 ${dataDir}
          chmod 400 ${dataDir}/*
        '';
      };
    };

    systemd.services = lib.mkIf (!config.mySystem.recoveryMode) {
      rustdesk-signal = {
        serviceConfig = {
          WorkingDirectory = lib.mkForce dataDir;
        };
      };
      rustdesk-relay = {
        serviceConfig = {
          WorkingDirectory = lib.mkForce dataDir;
        };
      };
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              directory = dataDir;
              user = "rustdesk";
              group = "rustdesk";
              mode = "700";
            }
          ];
        };
  };
}
