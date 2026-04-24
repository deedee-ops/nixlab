_: {
  flake.homeModules.features-home-rustdesk =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.rustdesk;
    in
    {
      options.features.home.rustdesk = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };

      config = {
        sops.secrets =
          lib.genAttrs [ "features/home/rustdesk/key" "features/home/rustdesk/relayHost" ]
            (_: {
              sopsFile = cfg.sopsSecretsFile;
            });

        home.packages = [ pkgs.rustdesk-flutter ];

        systemd.user.services.init-rustdesk = lib.mkHomeActivationAfterSops {
          name = "init-rustdesk";
          script = ''
            if [ ! -f "${config.xdg.configHome}/rustdesk/RustDesk2.toml" ]; then
              mkdir -p "${config.xdg.configHome}/rustdesk"
              RELAY_HOST="$(cat "${config.sops.secrets."features/home/rustdesk/relayHost".path}")"
              cat > "${config.xdg.configHome}/rustdesk/RustDesk2.toml" << EOF
            [options]
            key = '$(cat "${config.sops.secrets."features/home/rustdesk/key".path}")'
            api-server = 'https://$RELAY_HOST'
            relay-server = '$RELAY_HOST'
            custom-rendezvous-server = '$RELAY_HOST'
            EOF
            fi
          '';
        };
      };
    };
}
