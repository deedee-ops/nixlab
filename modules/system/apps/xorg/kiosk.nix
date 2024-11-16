{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.xorg.kiosk;
  kioskConfig = pkgs.writeText "config" ''
    # needed to force i3 to think this is v4 config
    workspace_layout default

    default_border none
    for_window [class=".*"] fullscreen

    exec ${lib.getExe pkgs.xorg.xset} s off -dpms
    exec ${cfg.command}
  '';
in
{
  options.mySystemApps.xorg.kiosk = {
    enable = lib.mkEnableOption "xorg";
    command = lib.mkOption {
      type = lib.types.str;
      description = "Command to be run by default in kiosk.";
    };
  };

  config = lib.mkIf cfg.enable {
    mySystemApps.xorg = {
      autoLogin = true;
      windowManager = "i3";
    };

    # ugly hack, to bypass homemanager and generate i3 config in primary user home dir directly
    # it's kiosk mode, so we can live with it

    system.activationScripts = {
      i3-kiosk = ''
        mkdir -p /home/${config.mySystem.primaryUser}/.config/i3
        cp ${kioskConfig} /home/${config.mySystem.primaryUser}/.config/i3/config

        chown ${config.mySystem.primaryUser} /home/${config.mySystem.primaryUser}/.config /home/${config.mySystem.primaryUser}/.config/i3 /home/${config.mySystem.primaryUser}/.config/i3/config
      '';
    };
  };
}
