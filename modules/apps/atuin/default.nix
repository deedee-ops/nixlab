{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.atuin;
  homeDir = config.home.homeDirectory;
in
{
  options.myHomeApps.atuin = {
    enable = lib.mkEnableOption "atuin";
    useDaemon = lib.mkOption {
      type = lib.types.bool;
      description = "Use atuin daemon - experimental, but helps with ZFS.";
      default = osConfig.mySystem.filesystem == "zfs";
    };
    syncAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Server sync address, including protocol.";
      example = "https://atuin.example.com";
      default = null;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "home/apps/atuin";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.mkIf (cfg.syncAddress != null) {
      "${cfg.sopsSecretPrefix}/encrypted_key" = { };
      "${cfg.sopsSecretPrefix}/username" = { };
      "${cfg.sopsSecretPrefix}/password" = { };
    };

    home.activation = lib.optionalAttrs (cfg.syncAddress != null) {
      init-atuin = lib.hm.dag.entryAfter [ "sopsNix" ] ''
        # headless atuin is a nightmare
        export ATUIN_SESSION=dummy

        ${lib.getExe config.programs.atuin.package} login \
        -u "$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/username".path})" \
        -p "$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/password".path})" || true
        ${lib.getExe config.programs.atuin.package} sync -f || true
      '';
    };

    programs = {
      atuin = {
        enable = true;

        enableZshIntegration = true;
        flags = [ "--disable-up-arrow" ];

        settings =
          {
            dialect = "uk";
            auto_sync = true;
            update_check = false;
            search_mode = "fuzzy";
            filter_mode = "host";
            style = "compact";
            invert = false;
            inline_height = 16;
            show_preview = true;
            show_help = false;
            show_tabs = false;
            exit_mode = "return-original";
            store_failed = true;
            secrets_filter = true;
            enter_accept = false;

            sync.records = true;
            dotfiles.enabled = false;

            daemon = {
              enabled = cfg.useDaemon;
              sync_frequency = 60;
              socket_path = "${config.xdg.dataHome}/atuin/atuin.sock";
            };
          }
          // lib.optionalAttrs osConfig.mySystem.impermanence.enable {
            db_path = "${osConfig.mySystem.impermanence.persistPath}${homeDir}/.local/share/atuin/history.db";
          }
          // lib.optionalAttrs (cfg.syncAddress != null) {
            key_path = config.sops.secrets."${cfg.sopsSecretPrefix}/encrypted_key".path;
            sync_address = cfg.syncAddress;
            sync_frequency = "0";
          };
      };
      zsh.initContent = lib.mkOrder 999 ''
        # add atuin path to $PATH so it will be available for root as well
        export PATH="$PATH:${config.programs.atuin.package}/bin"
      '';
    };

    systemd.user.services.atuin = lib.mkIf cfg.useDaemon {
      Unit = {
        After = [
          "network.target"
          "sops-nix.service"
        ];
        Description = "atuin daemon";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service.ExecStart = lib.getExe (
        pkgs.writeShellScriptBin "atuin-daemon.sh" ''
          rm -rf "${config.programs.atuin.settings.daemon.socket_path}"
          ${lib.getExe config.programs.atuin.package} daemon
        ''
      );
    };
  };
}
