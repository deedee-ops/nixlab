{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.obsidian;
in
{
  options.myHomeApps.obsidian = {
    enable = lib.mkEnableOption "obsidian";
    PKMpath = lib.mkOption {
      type = lib.types.str;
      description = "Path to PKM";
      default = "${config.home.homeDirectory}/PKM";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
        lib.mkIf osConfig.mySystem.impermanence.enable (
          [
            {
              directory = ".config/obsidian";
              method = "symlink";
            }
          ]
          ++ lib.optionals (lib.hasPrefix "${config.home.homeDirectory}/" cfg.PKMpath) [
            {
              directory = builtins.replaceStrings [ "${config.home.homeDirectory}/" ] [ "" ] cfg.PKMpath;
              method = "symlink";
            }
          ]
        );

      packages = [
        pkgs.obsidian # for quicklaunch entry
      ];

      activation.init-obsidian = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${cfg.PKMpath}/Inbox";
      '';
    };

    myHomeApps = {
      awesome = {
        autorun = [ (lib.getExe pkgs.obsidian) ];
        awfulRules = [
          {
            rule = {
              class = "obsidian";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = if config.myHomeApps.whatsie.enable then " 6 " else " 7 ";
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
