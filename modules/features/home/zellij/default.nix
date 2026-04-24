_: {
  flake.homeModules.features-home-zellij = _: {
    config = {
      stylix.targets.zellij.enable = true;

      programs.zellij = {
        enable = true;
        settings = {
          default_layout = "compact";
          default_mode = "locked";
          mouse_mode = true;
          pane_frames = false;
          scroll_buffer_size = 10000;
          show_startup_tips = false;
        };
      };
    };
  };
}
