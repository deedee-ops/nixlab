{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.obsidian;
  obsidianPkg = pkgs.obsidian.overrideAttrs (oldAttrs: {
    postInstall = ({ postInstall = ""; } // oldAttrs).postInstall + ''
      wrapProgram "$out/bin/obsidian" \
        --set 'HOME' '${config.xdg.configHome}'
    '';
  });
in
{
  options.myHomeApps.obsidian = {
    enable = lib.mkEnableOption "obsidian";
    desktopNumber = lib.mkOption {
      type = lib.types.int;
      description = "Virtual desktop number.";
      default = 8;
    };
    PKMpath = lib.mkOption {
      type = lib.types.str;
      description = "Path to PKM";
      default = "${config.home.homeDirectory}/PKM";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        obsidianPkg # for quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome = {
        autorun = [ "${lib.getExe pkgs.wmctrl} -x -a obsidian || ${lib.getExe obsidianPkg}" ];
        awfulRules = [
          {
            rule = {
              class = "obsidian";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = " ${builtins.toString cfg.desktopNumber} ";
            };
          }
          {
            rule = {
              class = "obsd-new-note";
            };
            properties = {
              floating = true;
            };
          }
        ];
        extraConfig =
          let
            spawnDaily = pkgs.writeShellScriptBin "spawn-obsidian-daily.sh" ''
              ${lib.getExe' config.myHomeApps.awesome.package "awesome-client"} '
              for _, c in ipairs(client.get()) do
                  if c.class and c.class:lower():find("obsidian") then
                      local t = c.first_tag
                      if t then
                          t:view_only()
                          awful.screen.focus(t.screen)
                      end
                      client.focus = c
                      c:raise()
                      break
                  end
              end
              '
              ${lib.getExe' pkgs.xdg-utils "xdg-open"} 'obsidian://daily'
            '';
          in
          ''
            local obsidiankeys = gears.table.join(
              awful.key({ RC.vars.modkey }, "d", function()
                awful.util.spawn("${lib.getExe spawnDaily}")
              end, { description = "trigger daily obsidian note", group = "apps" })
            )

            RC.globalkeys = gears.table.join(RC.globalkeys, obsidiankeys)
            root.keys(RC.globalkeys)
          '';
      };
      allowUnfree = [ "obsidian" ];
    };
  };
}
