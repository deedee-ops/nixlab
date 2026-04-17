_: {
  flake.homeModules.features-home-vicinae =
    { config, ... }:
    {
      config = {
        stylix.targets.vicinae.enable = true;

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
              dark.name = "stylix";
              light.name = "stylix";
            };
          };
        };

      };
    };
}
