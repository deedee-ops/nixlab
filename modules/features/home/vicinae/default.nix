_: {
  flake.homeModules.features-home-vicinae =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.vicinae;
    in
    {
      options.features.home.vicinae = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };

      config = {
        sops.secrets = lib.genAttrs [ "features/home/vicinae/ytcast.json" ] (_: {
          sopsFile = cfg.sopsSecretsFile;
          path = "${config.xdg.cacheHome}/ytcast/ytcast.json";
        });

        stylix.targets.vicinae.enable = !config.programs.noctalia-shell.enable;
        programs.noctalia-shell.settings.templates.activeTemplates = [
          {
            enabled = true;
            id = "vicinae";
          }
        ];

        home = {
          activation.init-vicinae-extensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "${config.xdg.dataHome}/vicinae/extensions"
            cp -r "${./extensions}/"* "${config.xdg.dataHome}/vicinae/extensions"
            chmod -R u+w "${config.xdg.dataHome}/vicinae/extensions"

            ${lib.getExe' pkgs.systemd "systemctl"} --user restart vicinae
          '';
          packages = [
            pkgs.ytcast
          ];
        };

        services.vicinae = {
          enable = true;
          systemd = {
            enable = true;
            autoStart = true;
            environment = {
              # workaround against service limitations
              PATH = "/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin";
            };
          };

          settings = {
            close_on_focus_loss = true;
            escape_key_behavior = "close_window";
            pop_to_root_on_close = true;
            launcher_window.opacity = 1.0;
            telemetry = {
              system_info = false;
            };
            theme = {
              dark.name = if config.programs.noctalia-shell.enable then "noctalia" else "stylix";
              light.name = if config.programs.noctalia-shell.enable then "noctalia" else "stylix";
            };
          };
        };

      };
    };
}
