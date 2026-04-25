_: {
  flake.homeModules.features-home-yazi =
    { config, lib, ... }:
    {
      stylix.targets.yazi.enable = !config.programs.noctalia-shell.enable;
      programs.noctalia-shell.settings.templates.activeTemplates = [
        {
          enabled = true;
          id = "yazi";
        }
      ];

      programs.yazi = {
        enable = true;
        shellWrapperName = "y";

        keymap = {
          mgr = {
            prepend_keymap = [
              {
                on = "d";
                run = "remove --permanently";
                desc = "Remove permanently.";
              }
            ];
          };
        };
        theme = {
          indicator = {
            preview = {
              underline = false;
            };
          };
        }
        // lib.optionalAttrs config.programs.noctalia-shell.enable {
          flavor = {
            dark = "noctalia";
            light = "noctalia";
          };
        };
        settings = {
          mgr = {
            ratio = [
              1
              3
              6
            ];
            sort_by = "alphabetical";
            sort_sensitive = false;
            sort_dir_first = true;
            show_hidden = true;
            show_symlink = true;
          };
          preview = {
            wrap = "yes";
            tab_size = 2;
            max_width = 2700;
            max_height = 2050;
          };
        };
      };
    };
}
