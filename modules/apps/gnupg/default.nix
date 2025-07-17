{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.gnupg;
in
{
  options.myHomeApps.gnupg = {
    enable = lib.mkEnableOption "gnupg" // {
      default = true;
    };
    enableGpgAgent = lib.mkEnableOption "gpg-agent" // {
      default = true;
    };
    appendOptions = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings to gpg.";
    };
    enableYubikey = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Configures gpg-agent and gpg to support yubikey stored private keys.";
    };
    pinentryPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pinentry;
      description = "Pinentry package.";
    };
    publicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of public keys to be imported.";
    };
    privateKeys = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              description = "Private key id.";
            };
            path = lib.mkOption {
              type = lib.types.str;
              description = "Private key path.";
            };
          };
        }
      );
      default = [ ];
    };
    rememberPasswordTime = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      description = "Time in seconds, which password will be cached by gpg-agent (and not asked again).";
      default = null;
      example = 3600;
    };
  };

  config = lib.mkIf cfg.enable {
    myHomeApps.shellInitScriptContents =
      ''
        if [ "$USER" = "${osConfig.mySystem.primaryUser}" ]; then
      ''
      + builtins.concatStringsSep "\n" (
        builtins.map (key: ''
          ${lib.getExe pkgs.gnupg} --list-secret-keys ${key.id} > /dev/null || gpg --batch --import ${key.path}
        '') cfg.privateKeys
      )
      + ''
        fi
      '';

    home = {
      activation.gpg = lib.mkIf cfg.enableYubikey (
        lib.hm.dag.entryAfter [ "sopsNix" ] ''
          export GNUPGHOME="${config.xdg.dataHome}/gnupg"
          run ${pkgs.gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
        ''
      );
      shellAliases.gpgkill = "${lib.getExe' pkgs.gnupg "gpgconf"} --kill gpg-agent";
    };

    programs.gpg = {
      enable = true;

      homedir = "${config.xdg.dataHome}/gnupg";
      mutableKeys = false;
      mutableTrust = false;

      publicKeys = builtins.map (src: {
        source = src;
        trust = "ultimate";
      }) cfg.publicKeys;

      settings = cfg.appendOptions;
    };

    services.gpg-agent = lib.mkIf cfg.enableGpgAgent {
      enable = true;
      enableScDaemon = true;
      defaultCacheTtl = cfg.rememberPasswordTime;
      pinentry.package = cfg.pinentryPackage;
    };

    systemd.user.services.gnupg-create-socketdir = lib.mkIf cfg.enableYubikey {
      Install = {
        WantedBy = [ "default.target" ];
      };
      Unit = {
        Description = "Create GnuPG socket directory";
      };
      Service = {
        Type = "oneshot";
        Environment = [ "GNUPGHOME=${config.xdg.dataHome}/gnupg" ];
        ExecStart = "${lib.getExe' pkgs.gnupg "gpgconf"} --create-socketdir";
      };
    };
  };
}
