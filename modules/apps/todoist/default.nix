{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.todoist;
  tod = pkgs.callPackage ../../pkgs/tod.nix { };
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
      persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
        lib.mkIf osConfig.mySystem.impermanence.enable [
          {
            directory = ".config/Todoist";
            method = "symlink";
          }
        ];

      packages = [
        pkgs.todoist-electron
      ];
    };

    myHomeApps = {
      awesome = {
        # on first run todoist dies for some odd reason, so let's run it twice
        autorun = [
          "${lib.getExe pkgs.bash} -c '${lib.getExe pkgs.todoist-electron}; ${lib.getExe pkgs.todoist-electron}'"
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
      rofi.todoCommand = "${lib.getExe tod} task quick-add --content";
    };

    home = {
      activation = {
        todoist = lib.hm.dag.entryAfter [ "sopsNix" ] ''
          sed -e 's@##PATH##@${config.xdg.configHome}/tod.cfg@g' \
              -e "s@##TOKEN##@$(cat ${config.sops.secrets."${cfg.apiKeySopsSecret}".path})@g" \
              -e "s@##TIMEZONE##@${osConfig.mySystem.time.timeZone}@g" \
              ${./tod.cfg} > "${config.xdg.configHome}/tod.cfg"
        '';
      };
    };
  };
}
