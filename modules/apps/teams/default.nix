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
      myHomeApps.awesome.autorun = [ (lib.getExe teamsPkg) ];

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
