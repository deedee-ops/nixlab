{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.scripts.docwatcher;
in
{
  options.myHomeApps.scripts.docwatcher = {
    enable = lib.mkEnableOption "docwatcher scripts";
    watchDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory to be watched for new documents.";
    };
    googleDrive = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "syncing to google drive";
          path = lib.mkOption {
            type = lib.types.str;
            description = "Path on google drive";
          };
          rcloneConfigSopsSecret = lib.mkOption {
            type = lib.types.str;
            description = "Sops secret name containing rclone configuration.";
            default = "home/scripts/docwatcher/rclone_config";
          };
        };
      };
      default = {
        enable = false;
      };
      description = "Send watched documents to google drive.";
    };
    mail = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "sending via email";
          from = lib.mkOption {
            type = lib.types.str;
            description = "'From' field of an email.";
          };
          to = lib.mkOption {
            type = lib.types.str;
            description = "Recipient of an email.";
          };
          subject = lib.mkOption {
            type = lib.types.str;
            description = "Subject of an email.";
          };
          body = lib.mkOption {
            type = lib.types.str;
            description = "Body of an email.";
            default = "";
          };
          swaksConfigSopsSecret = lib.mkOption {
            type = lib.types.str;
            description = "Sops secret name containing swaks configuration.";
            default = "home/scripts/docwatcher/swaks_config";
          };
        };
      };
      default = {
        enable = false;
      };
      description = "Send watched documents via email.";
    };
    paperless = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "syncing to paperless";
          consumeDir = lib.mkOption {
            type = lib.types.str;
            description = "Path to paperless consume dir.";
          };
        };
      };
      default = {
        enable = false;
      };
      description = "Send watched documents to paperless.";
    };
    ssh = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "syncing via ssh";
          host = lib.mkOption {
            type = lib.types.str;
            description = "Hostname.";
          };
          targetDir = lib.mkOption {
            type = lib.types.str;
            description = "Target directory.";
          };
        };
      };
      default = {
        enable = false;
      };
      description = "Send watched documents to remote directory via scp.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "${cfg.googleDrive.rcloneConfigSopsSecret}" = { };
      "${cfg.mail.swaksConfigSopsSecret}" = { };
    };

    home.persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
      lib.mkIf osConfig.mySystem.impermanence.enable [
        ".config/rclone"
      ];

    systemd.user.services.docwatcher = {
      Unit = {
        After = "network.target";
        Description = "docwatcher";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Environment =
          [
            "GDRIVE_ENABLE=${if cfg.googleDrive.enable then "true" else "false"}"
            "MAIL_ENABLE=${if cfg.mail.enable then "true" else "false"}"
            "PAPERLESS_ENABLE=${if cfg.paperless.enable then "true" else "false"}"
            "SSH_ENABLE=${if cfg.ssh.enable then "true" else "false"}"
            "WATCH_DIR=${cfg.watchDir}"
            "PATH=${
              lib.makeBinPath [
                pkgs.coreutils-full
                pkgs.inotify-tools
                pkgs.libnotify
                pkgs.openssh
                pkgs.rclone
                pkgs.swaks
              ]
            }:$PATH"
          ]
          ++ (lib.optionals cfg.googleDrive.enable [
            "GDRIVE_DIR=${cfg.googleDrive.path}"
          ])
          ++ (lib.optionals cfg.mail.enable [
            "MAIL_FROM=\"${cfg.mail.from}\""
            "MAIL_TO=${cfg.mail.to}"
            "MAIL_SUBJECT=${cfg.mail.subject}"
            "MAIL_BODY=${cfg.mail.body}"
            "MAIL_SWAKS_CFG_PATH=${config.sops.secrets."${cfg.mail.swaksConfigSopsSecret}".path}"
          ])
          ++ (lib.optionals cfg.paperless.enable [
            "PAPERLESS_CONSUME_DIR=${cfg.paperless.consumeDir}"
          ])
          ++ (lib.optionals cfg.ssh.enable [
            "SSH_HOST=${cfg.ssh.host}"
            "SSH_TARGET=${builtins.replaceStrings [ "%" ] [ "%%" ] cfg.ssh.targetDir}"
          ]);
        ExecStartPre = lib.getExe (
          pkgs.writeShellScriptBin "rclone-pre" ''
            [ ! -f "${config.xdg.configHome}/rclone/rclone.conf" ] && cp ${
              config.sops.secrets."${cfg.googleDrive.rcloneConfigSopsSecret}".path
            } "${config.xdg.configHome}/rclone/rclone.conf"
            true
          ''
        );
        ExecStart = lib.getExe (
          pkgs.writeShellScriptBin "docwatcher.sh" (builtins.readFile ./docwatcher.sh)
        );
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
