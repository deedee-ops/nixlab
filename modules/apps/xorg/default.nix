{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.xorg;
in
{
  imports = [
    ./autorandr.nix
    ./gtk.nix
    ./picom.nix
    ./qt.nix
  ];

  options.myHomeApps.xorg = {
    mapRightCtrlToAltGr = lib.mkEnableOption "forcefuly map right Ctrl to AltGr";
    terminal = lib.mkOption {
      type = lib.types.package;
      description = "Default terminal package.";
      default = pkgs.alacritty;
    };
    trackpadSupport = lib.mkEnableOption "trackpad support";
  };

  config = lib.mkIf osConfig.mySystemApps.xorg.enable {
    stylix.targets.xresources.enable = true;

    fonts.fontconfig.enable = true;

    xsession = {
      enable = true;
      initExtra =
        (lib.optionalString cfg.trackpadSupport ''
          ${lib.getExe (pkgs.callPackage ../../pkgs/libinput-three-finger-drag.nix { })} &
        '')
        + (lib.optionalString cfg.mapRightCtrlToAltGr ''
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 105 = Mode_switch Mode_switch Mode_switch Mode_switch"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 38 = a A aogonek Aogonek aogonek Aogonek aogonek Aogonek a A aogonek Aogonek"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 54 = c C cacute Cacute cacute Cacute cacute Cacute"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 26 = e E eogonek Eogonek eogonek Eogonek eogonek Eogonek e E eogonek Eogonek"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 46 = l L lstroke Lstroke lstroke Lstroke lstroke Lstroke l L lstroke Lstroke"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 57 = n N nacute Nacute nacute Nacute nacute Nacute n N nacute Nacute"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 32 = o O oacute Oacute oacute Oacute oacute Oacute o O oacute Oacute"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 39 = s S sacute Sacute sacute Sacute sacute Sacute s S sacute Sacute"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 53 = x X zacute Zacute zacute Zacute zacute Zacute x X zacute Zacute"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 52 = z Z zabovedot Zabovedot zabovedot Zabovedot zabovedot Zabovedot z Z zabovedot Zabovedot"
          ${lib.getExe pkgs.xorg.xmodmap} -e "keycode 54 = c C cacute Cacute cacute Cacute cacute"
        '');
    };
    xdg.mimeApps.enable = true;

    xresources = {
      path = "${config.xdg.configHome}/X11/xresources";
      properties = {
        "Xft.dpi" = 192;
      };
    };

    home = {
      packages = [
        pkgs.roboto
        pkgs.xclip # pbcopy and pbpaste
      ];

      sessionVariables = {
        XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
      };
    };
  };
}
