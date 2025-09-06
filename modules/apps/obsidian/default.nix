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

      activation.init-obsidian = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${cfg.PKMpath}/Inbox";
      '';
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
            terminalRunners = {
              alacritty = "${lib.getExe config.programs.alacritty.package} --class 'obsd-new-note' -e";
              kitty = "${lib.getExe config.programs.kitty.package} --class 'obsd-new-note' --";
              ghostty = "${lib.getExe config.programs.ghostty.package} --class='obsd-new-note' -e";
            };
          in
          ''
            local home = os.getenv("HOME")
            local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
            local obsidiankeys = gears.table.join(
              awful.key({ RC.vars.modkey, "Shift" }, "a", function()
                awful.util.spawn("${terminalRunners."${config.myHomeApps.xorg.terminal.pname}"} "
                  .. "${lib.getExe config.programs.neovim.package} "
                  .. "${cfg.PKMpath}/Inbox/" .. os.time() .. ".md"
                )
              end, { description = "new obsidian note", group = "apps" })
            )

            RC.globalkeys = gears.table.join(RC.globalkeys, obsidiankeys)
            root.keys(RC.globalkeys)
          '';
      };
      allowUnfree = [ "obsidian" ];
    };
  };
}
