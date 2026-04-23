_: {
  flake.homeModules.features-home-atuin =
    { config, lib, ... }:
    let
      cfg = config.features.home.atuin;
    in
    {
      options.features.home.atuin = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };
      config = {
        sops.secrets =
          lib.genAttrs
            [ "features/home/atuin/encryptedKey" "features/home/atuin/username" "features/home/atuin/password" ]
            (_: {
              sopsFile = cfg.sopsSecretsFile;
            });

        programs = {
          atuin = {
            enable = true;

            daemon.enable = true;
            enableZshIntegration = true;
            flags = [ "--disable-up-arrow" ];

            settings = {
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

              logs.dir = "${config.xdg.stateHome}/atuin/logs";
              sync.records = true;
              dotfiles.enabled = false;

              key_path = config.sops.secrets."features/home/atuin/encryptedKey".path;
              sync_address = "https://atuin.ajgon.casa";
              sync_frequency = "0";
            };
          };
        };

        systemd.user.services.init-atuin = lib.mkHomeActivationAfterSops {
          name = "init-atuin";
          script = ''
            # headless atuin is a nightmare
            export ATUIN_SESSION=dummy

            ${lib.getExe config.programs.atuin.package} login \
            -u "$(cat ${config.sops.secrets."features/home/atuin/username".path})" \
            -p "$(cat ${config.sops.secrets."features/home/atuin/password".path})" || true
            ${lib.getExe config.programs.atuin.package} sync -f || true
          '';
        };
      };
    };
}
