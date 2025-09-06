{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.whatsapp;
in
{
  options.myHomeApps.whatsapp = {
    enable = lib.mkEnableOption "whatsapp";
    desktopNumber = lib.mkOption {
      type = lib.types.int;
      description = "Virtual desktop number.";
      default = 0;
    };
  };

  config =
    let
      whatsappPkg = pkgs.writeShellScriptBin "whatsapp" ''
        export HOME="${config.xdg.configHome}"
        ${lib.getExe pkgs.wmctrl} -x -a whatsapp-pwa || ${lib.getExe pkgs.ungoogled-chromium} --app="https://web.whatsapp.com/" --class="whatsapp-pwa" --user-data-dir="${config.xdg.stateHome}/whatsapp"
      '';
    in
    lib.mkIf cfg.enable {
      myHomeApps.awesome = {
        autorun = [ (lib.getExe whatsappPkg) ];
        awfulRules = [
          {
            rule = {
              class = "whatsapp-pwa";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = " ${builtins.toString cfg.desktopNumber} ";
            };
          }
        ];
      };

      xdg = {
        dataFile = {
          "applications/WhatsApp.desktop".text = ''
            [Desktop Entry]
            Name=WhatsApp
            Comment=WhatsApp Web Client
            Exec=${lib.getExe whatsappPkg} %U
            Icon=whatsapp
            Terminal=false
            Type=Application
            Encoding=UTF-8
            Categories=Network;InstantMessaging;Chat
            StartupWMClass=whatsapp-pwa
            Name[en_US]=WhatsApp
          '';
        };
      };
    };
}
