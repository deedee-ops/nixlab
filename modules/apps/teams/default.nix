{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.teams;
in
{
  options.myHomeApps.teams = {
    enable = lib.mkEnableOption "teams";
  };

  config =
    let
      teamsPkg = pkgs.writeShellScriptBin "teams" ''
        ${lib.getExe pkgs.ungoogled-chromium} --app="https://teams.microsoft.com/" --class="teams-pwa" --user-data-dir="${config.xdg.stateHome}/teams"
      '';
    in
    lib.mkIf cfg.enable {
      myHomeApps.awesome = {
        autorun = [ (lib.getExe teamsPkg) ];
        awfulRules = [
          {
            rule = {
              class = "teams-pwa";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = if config.myHomeApps.whatsie.enable then " 7 " else " 8 ";
            };
          }
        ];
        floatingClients.name = [
          "teams.microsoft.com is sharing a window."
          "teams.microsoft.com is sharing your screen."
        ];
      };

      xdg = {
        dataFile = {
          "applications/Teams.desktop".text = ''
            [Desktop Entry]
            Name=Microsoft Teams
            Comment=Unofficial Microsoft Teams client
            Exec=${lib.getExe teamsPkg} %U
            Icon=teams-for-linux
            Terminal=false
            Type=Application
            Encoding=UTF-8
            Categories=Network;InstantMessaging;Chat
            StartupWMClass=teams-pwa
            Name[en_US]=Microsoft Teams
          '';
        };
      };
    };
}
