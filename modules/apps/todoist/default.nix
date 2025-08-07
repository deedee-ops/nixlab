{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.todoist;
  todPkg = pkgs.callPackage ../../pkgs/tod.nix { };
  todoistPkg = pkgs.symlinkJoin {
    name = "todoist-electron";
    paths = [
      (pkgs.writeShellScriptBin "todoist-electron" ''
        export HOME="${config.xdg.configHome}"
        exec ${lib.getExe pkgs.todoist-electron} "%@"
      '')
      pkgs.todoist-electron
    ];
    postBuild = ''
      sed -i"" -E "s@Exec=[^ ]+@Exec=$out/bin/todoist-electron@" $out/share/applications/todoist.desktop
    '';
    meta.mainProgram = "todoist-electron";
  };
in
{
  options.myHomeApps.todoist = {
    enable = lib.mkEnableOption "todoist";
    apiKeySopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "home/apps/todoist/api_key";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.apiKeySopsSecret}" = { };

    home = {
      packages = [
        todoistPkg # for quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome = {
        # on first run todoist dies for some odd reason, so let's run it twice
        autorun = [
          "${lib.getExe pkgs.bash} -c '${lib.getExe todoistPkg}; ${lib.getExe todoistPkg}'"
        ];
        awfulRules = [
          {
            rule = {
              class = "Todoist";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = if config.myHomeApps.awesome.singleScreen then " 5 " else " 1 ";
            };
          }
        ];
      };
      allowUnfree = [ "todoist-electron" ];
      rofi.todoCommand = "${lib.getExe todPkg} task quick-add --content";
    };

    systemd.user.services.init-todoist = lib.mkHomeActivationAfterSops "init-todoist" ''
      sed -e 's@##PATH##@${config.xdg.configHome}/tod.cfg@g' \
          -e "s@##TOKEN##@$(cat ${config.sops.secrets."${cfg.apiKeySopsSecret}".path})@g" \
          -e "s@##TIMEZONE##@${osConfig.mySystem.time.timeZone}@g" \
          ${./tod.cfg} > "${config.xdg.configHome}/tod.cfg"
    '';
  };
}
