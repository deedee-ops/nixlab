{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.planify;

  mkPlanifyWrapper =
    name: cmd:
    (pkgs.writeShellScriptBin name ''
      # hack to make planify behave properly in high DPI (GDK_SCALE will scale icons, while settings.ini hack will scale font back down)
      TMPCONFIG="$(mktemp -d)"
      cp -arL "$XDG_CONFIG_HOME/gtk-4.0" "$TMPCONFIG"
      cp -arL "$XDG_CONFIG_HOME/dconf" "$TMPCONFIG"
      NEWSIZE="$(( "$(sed -nE 's/gtk-font-name[^0-9]*([0-9]+)$/\1/p' "$TMPCONFIG/gtk-4.0/settings.ini")" / 2 ))"
      sed -i -E "s/(gtk-font-name[^0-9]*) [0-9]+$/\1 $NEWSIZE/" "$TMPCONFIG/gtk-4.0/settings.ini"

      export GDK_SCALE=2
      export XDG_CONFIG_HOME="$TMPCONFIG"
      ${cmd}
      rm -rf "$TMPCONFIG"
    '');

  planifyPkg = mkPlanifyWrapper "planify" (lib.getExe pkgs.planify);
  planifyQuickAddPkg = mkPlanifyWrapper "planify-quickadd" (
    lib.getExe' pkgs.planify "io.github.alainm23.planify.quick-add"
  );
in
{
  options.myHomeApps.planify = {
    enable = lib.mkEnableOption "planify";
    desktopNumber = lib.mkOption {
      type = lib.types.int;
      description = "Virtual desktop number.";
      default = if config.myHomeApps.awesome.singleScreen then 6 else 1;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      planifyPkg
      planifyQuickAddPkg
    ];

    myHomeApps.awesome = {
      awfulRules = [
        {
          rule = {
            class = "io.github.alainm23.planify";
          };
          except = {
            class = "io.github.alainm23.planify.quick-add";
          };
          properties = {
            screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
            tag = " ${builtins.toString cfg.desktopNumber} ";
          };
        }
      ];
      floatingClients.class = [ "io.github.alainm23.planify.quick-add" ];
      extraConfig = ''
        local home = os.getenv("HOME")
        local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
        local planifykeys = gears.table.join(
          awful.key({ RC.vars.modkey }, "e", function()
            awful.util.spawn("${lib.getExe planifyQuickAddPkg}")
          end, { description = "planify quick add", group = "apps" })
        )

        RC.globalkeys = gears.table.join(RC.globalkeys, planifykeys)
        root.keys(RC.globalkeys)
      '';
    };

    myHomeApps.awesome.autorun = [ (lib.getExe planifyPkg) ];
  };
}
