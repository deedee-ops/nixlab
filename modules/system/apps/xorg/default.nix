{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.xorg;
in
{
  imports = [
    ./kiosk.nix
  ];

  options.mySystemApps.xorg = {
    enable = lib.mkEnableOption "xorg";
    autoLogin = lib.mkEnableOption "autologin for xorg";
    windowManager = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Window manager to use.";
      default = null;
    };
    sddmThemePackage = lib.mkOption {
      type = lib.types.package;
      description = "Theme package to use for SDDM.";
      default = pkgs.catppuccin-sddm-corners;
    };
    userAutorun = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "List of applications to run when primary user starts X session.";
      default = { };
      example = lib.options.literalExpression ''
        { bluetooth = (lib.getExe' pkgs.blueman "blueman-applet"); }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        sddm = {
          enable = true;
          theme = cfg.sddmThemePackage.pname;
        };
        autoLogin = lib.mkIf cfg.autoLogin {
          enable = true;
          user = config.mySystem.primaryUser;
        };
      };

      xserver =
        {
          enable = true;
        }
        // lib.optionalAttrs (cfg.windowManager != null) {
          windowManager."${cfg.windowManager}".enable = true;
        };
    };

    # allow members of video group to adjust backlights
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${lib.getExe' pkgs.coreutils-full "chgrp"} video $sys$devpath/brightness", RUN+="${lib.getExe' pkgs.coreutils-full "chmod"} g+w $sys$devpath/brightness"
    '';

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ "/var/lib/sddm" ]; };

    environment.systemPackages = [
      cfg.sddmThemePackage
      # https://github.com/nix-community/home-manager/issues/3113
      pkgs.dconf
    ];

    programs.i3lock.enable =
      config.home-manager.users."${config.mySystem.primaryUser}".services.betterlockscreen.enable; # fixes various issues like PAM

    home-manager.users."${config.mySystem.primaryUser}".systemd.user.services = builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = {
          Unit = {
            After = "graphical-session-pre.target";
            Description = name;
            PartOf = "graphical-session.target";
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = builtins.getAttr name cfg.userAutorun;
            Restart = "on-failure";
            RestartSec = 3;
          };
        };
      }) (builtins.attrNames cfg.userAutorun)
    );
  };
}
