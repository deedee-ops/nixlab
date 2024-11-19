{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.speedcrunch;
in
{
  options.myHomeApps.speedcrunch = {
    enable = lib.mkEnableOption "speedcrunch";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.speedcrunch
      ];
    };

    myHomeApps.awesome.extraConfig = ''
      local home = os.getenv("HOME")
      local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
      local speedcrunchkeys = gears.table.join(
        awful.key({ RC.vars.modkey }, "c", function()
          awful.util.spawn("${lib.getExe pkgs.speedcrunch}")
        end, { description = "calculator", group = "apps" })
      )

      RC.globalkeys = gears.table.join(RC.globalkeys, speedcrunchkeys)
      root.keys(RC.globalkeys)
    '';
  };
}
