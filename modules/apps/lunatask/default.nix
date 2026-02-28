{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.lunatask;
  quickAddCmd = pkgs.writeShellScriptBin "lunatask-add.sh" ''
    ${lib.getExe pkgs.curl} \
    -X POST \
    -H "Authorization: bearer $(cat "${config.sops.secrets."${cfg.apiKeySopsSecret}".path}")" \
    -H 'Content-Type: application/json' \
    -d '{"name":"'"$*"'","area_id":"${cfg.defaultAreaID}"}' \
    'https://api.lunatask.app/v1/tasks'
  '';
in
{
  options.myHomeApps.lunatask = {
    enable = lib.mkEnableOption "lunatask";
    desktopNumber = lib.mkOption {
      type = lib.types.int;
      description = "Virtual desktop number.";
      default = if config.myHomeApps.awesome.singleScreen then 6 else 1;
    };
    defaultAreaID = lib.mkOption {
      type = lib.types.str;
      description = "Default area ID to add quick task.";
    };
    apiKeySopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "home/apps/lunatask/api_key";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.apiKeySopsSecret}" = { };

    home = {
      packages = [
        pkgs.lunatask
      ];
    };

    myHomeApps = {
      awesome = {
        # on first run lunatask dies for some odd reason, so let's run it twice
        autorun = [
          (lib.getExe pkgs.lunatask)
        ];
        awfulRules = [
          {
            rule = {
              class = "Lunatask";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = " ${builtins.toString cfg.desktopNumber} ";
            };
          }
        ];
      };
      allowUnfree = [ "lunatask" ];
      rofi.todoCommand = "${lib.getExe quickAddCmd}";
    };
  };
}
