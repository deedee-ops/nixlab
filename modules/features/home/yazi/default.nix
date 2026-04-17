{ self, inputs, ... }:
{
  flake.homeModules.features-home-yazi =
    { pkgs, ... }:
    {
      stylix.targets.yazi.enable = true;

      programs.yazi = {
        enable = true;
        package = self.packages."${pkgs.stdenv.hostPlatform.system}".yazi;
        shellWrapperName = "y";
      };
    };
  perSystem =
    { pkgs, ... }:
    {
      packages.yazi = inputs.wrapper-modules.wrappers.yazi.wrap {
        inherit pkgs;

        settings = {
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
          };
          yazi = {
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
    };
}
