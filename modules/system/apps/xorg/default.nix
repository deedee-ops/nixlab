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
    sddmThemeVariant = lib.mkOption {
      type = lib.types.enum [
        "astronaut"
        "black_hole"
        "cyberpunk"
        "hyprland_kath"
        "jake_the_dog"
        "japanese_aesthetic"
        "pixel_sakura"
        "pixel_sakura_static"
        "post-apocalyptic_hacker"
        "purple_leaves"
      ];
      description = "Variant of SDDM Astronauth theme.";
      default = "black_hole";
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

  config =
    let
      sddm-astronaut = pkgs.sddm-astronaut.override { embeddedTheme = cfg.sddmThemeVariant; };
    in
    lib.mkIf cfg.enable {
      services = {
        displayManager = {
          sddm = {
            enable = true;
            package = pkgs.kdePackages.sddm;
            theme = "sddm-astronaut-theme";
            extraPackages = [ sddm-astronaut ];
          };
          autoLogin = lib.mkIf cfg.autoLogin {
            enable = true;
            user = config.mySystem.primaryUser;
          };
        };

        xserver = {
          displayManager = {
            setupCommands = ''
              . ${config.home-manager.users."${config.mySystem.primaryUser}".xsession.profilePath}
            '';
          };
          enable = true;
        }
        // lib.optionalAttrs (cfg.windowManager != null) {
          windowManager."${cfg.windowManager}".enable = true;
        };
      };

      fonts.fontconfig.localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <dir>${sddm-astronaut}/share/sddm/themes/sddm-astronaut-theme/Fonts</dir>
        </fontconfig>
      '';

      # allow members of video group to adjust backlights
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="backlight", RUN+="${lib.getExe' pkgs.coreutils-full "chgrp"} video $sys$devpath/brightness", RUN+="${lib.getExe' pkgs.coreutils-full "chmod"} g+w $sys$devpath/brightness"
      '';

      environment = {
        etc = {
          "profile.local".text = lib.mkAfter ''
            . "${
              config.home-manager.users."${config.mySystem.primaryUser}".home.profileDirectory
            }/etc/profile.d/hm-session-vars.sh"
          '';
        };
        persistence."${config.mySystem.impermanence.persistPath}" =
          lib.mkIf config.mySystem.impermanence.enable
            { directories = [ "/var/lib/sddm" ]; };
        systemPackages = [
          pkgs.kdePackages.qtmultimedia
          sddm-astronaut
          # https://github.com/nix-community/home-manager/issues/3113
          pkgs.dconf
        ];
      };

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
