{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.zoom;
in
{
  options.myHomeApps.zoom = {
    enable = lib.mkEnableOption "zoom";
  };

  config =
    let
      zoomwrapper = pkgs.writeShellScriptBin "zoom-wrapper" ''
        TARGET="https://app.zoom.us/wc/$(echo "$@" | awk -F/ '{ print $NF }' | grep -Eo '(^|=)[0-9]{10,}' | tr -d '=')/join"
        ZOOM_PASSWORD="$(echo "$@" | grep -Eo '[?&]pwd=[^&]+' | tr '&' '?')"

        ${lib.getExe pkgs.ungoogled-chromium} --app="$TARGET$ZOOM_PASSWORD" --class="Zoom" --user-data-dir="${config.xdg.stateHome}/zoom"
      '';
    in
    lib.mkIf cfg.enable {
      home.packages = [ zoomwrapper ];

      myHomeApps.firefox.extraConfig = {
        "network.protocol-handler.expose.zoommtg" = false;
      };

      xdg = {
        dataFile = {
          "applications/Zoom.desktop".text = ''
            [Desktop Entry]
            Name=Zoom
            Comment=Zoom Video Conference
            Exec=${lib.getExe zoomwrapper} %U
            Icon=Zoom
            Terminal=false
            Type=Application
            Encoding=UTF-8
            Categories=Network;Application;
            StartupWMClass=zoom
            MimeType=x-scheme-handler/zoommtg;x-scheme-handler/zoomus;x-scheme-handler/tel;x-scheme-handler/callto;x-scheme-handler/zoomphonecall;application/x-zoom
            X-KDE-Protocols=zoommtg;zoomus;tel;callto;zoomphonecall;
            Name[en_US]=Zoom
          '';
        };

        mimeApps = {
          defaultApplications = {
            "x-scheme-handler/zoommtg" = "Zoom.desktop";
            "x-scheme-handler/zoomus" = "Zoom.desktop";
            "x-scheme-handler/tel" = "Zoom.desktop";
            "x-scheme-handler/callto" = "Zoom.desktop";
            "x-scheme-handler/zoomphonecall" = "Zoom.desktop";
            "application/x-zoom" = "Zoom.desktop";
          };
        };
      };
    };
}
