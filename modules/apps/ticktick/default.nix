{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.ticktick;

  ticktask = pkgs.writeShellScriptBin "ticktask" (
    ''
      curl_cmd="${lib.getExe pkgs.curl}"
      date_cmd="${lib.getExe' pkgs.coreutils-full "date"}"
      sed_cmd="${lib.getExe pkgs.gnused}"
      xdg_open_cmd="${lib.getExe' pkgs.xdg-utils "xdg-open"}"

      CLIENT_ID="$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/CLIENT_ID".path})"
      CLIENT_SECRET="$(cat ${config.sops.secrets."${cfg.sopsSecretPrefix}/CLIENT_SECRET".path})"

      # if you need new fresh access token, comment this line out
      access_token_file="${config.sops.secrets."${cfg.sopsSecretPrefix}/CLIENT_TOKEN".path}"
    ''
    + builtins.readFile ./ticktask.sh
  );

  ticktickPkg = pkgs.ticktick.overrideAttrs (oldAttrs: {
    postInstall = ({ postInstall = ""; } // oldAttrs).postInstall + ''
      wrapProgram "$out/bin/${oldAttrs.pname}" \
        --set 'HOME' '${config.xdg.configHome}'
    '';
  });
in
{
  options.myHomeApps.ticktick = {
    enable = lib.mkEnableOption "ticktick";
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "home/apps/ticktick/env";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "${cfg.sopsSecretPrefix}/CLIENT_ID" = { };
      "${cfg.sopsSecretPrefix}/CLIENT_SECRET" = { };
      "${cfg.sopsSecretPrefix}/CLIENT_TOKEN" = { };
    };

    home = {
      packages = [
        ticktickPkg # for quicklaunch entry
      ];
    };

    myHomeApps = {
      awesome = {
        autorun = [ (lib.getExe' ticktickPkg "ticktick") ];
        awfulRules = [
          {
            rule = {
              class = "ticktick";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = if config.myHomeApps.awesome.singleScreen then " 4 " else " 1 ";
            };
          }
        ];
      };
      allowUnfree = [ "ticktick" ];
      rofi.todoCommand = lib.getExe ticktask;
    };
  };
}
