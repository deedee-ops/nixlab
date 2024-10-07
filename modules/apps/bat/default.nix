{
  config,
  lib,
  ...
}:
let
  cfg = config.myApps.bat;
in
{
  options.myApps.bat = {
    enable = lib.mkEnableEnabledOption "bat";
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.bat.enable = true;

    home.shellAliases = {
      cat = "bat";
    };

    programs.bat = {
      enable = true;

      config = {
        pager = "never";
        style = "plain";
      };
    };
  };
}
