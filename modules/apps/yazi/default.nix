{
  config,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.yazi;
in
{
  options.myHomeApps.yazi = {
    enable = lib.mkEnableOption "yazi" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.yazi.enable = true;

    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
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
