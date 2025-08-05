{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.freerdp;
in
{
  options.myHomeApps.freerdp = {
    enable = lib.mkEnableOption "freerdp";
    windowsHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            host = lib.mkOption {
              type = lib.types.str;
            };
            domain = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            username = lib.mkOption {
              type = lib.types.str;
            };
            passwordSopsSecret = lib.mkOption {
              type = lib.types.str;
              description = "Sops secret name containing connection password.";
            };
          };
        }
      );
      description = "List of windows hosts which will be available in start menu to connect to.";
      example = {
        "My Windows 11" = "windows11.example.com";
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.mapAttrs' (_: value: {
      name = "${value.passwordSopsSecret}";
      value = { };
    }) cfg.windowsHosts;

    home.packages = [ pkgs.freerdp ];

    xdg.dataFile = lib.mapAttrs' (name: value: {
      name = "applications/${name}.desktop";
      value = {
        text = ''
          [Desktop Entry]
          Name=${name}
          Comment=RDP connection
          Exec=${lib.getExe (
            pkgs.writeShellScriptBin "rdp.sh" ''
              ${lib.getExe' pkgs.freerdp "xfreerdp"} /v:${value.host} /dynamic-resolution /workarea /scale:180 /d:${value.domain} /u:${value.username} /p:$(cat ${
                config.sops.secrets."${value.passwordSopsSecret}".path
              }) /cert:ignore
              [[ $? == 141 ]] && ${lib.getExe' pkgs.libnotify "notify-send"} "Connection to ${value.host} failed"
            ''
          )}
          Icon=${./windows.png}
          Terminal=false
          Type=Application
          Encoding=UTF-8
          Categories=Network
          StartupWMClass=windows-rdp
          Name[en_US]=${name}
        '';
      };
    }) cfg.windowsHosts;
  };
}
