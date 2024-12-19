{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
{
  options.mySystem = {
    allowUnfree = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of allowed unfree packages.";
      default = [ ];
    };

    extraModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Extra modules to load on boot.";
      default = [ ];
      example = [ "thunderbolt" ];
    };

    extraUdevRules = lib.mkOption {
      type = lib.types.lines;
      description = "Extra udev rules.";
      default = "";
    };

    filesystem = lib.mkOption {
      type = lib.types.enum [
        "ext4"
        "zfs"
      ];
      description = "Global filesystem for the system disks. As a rule of thumb - use 'ext4' for VMs and 'zfs' for bare metal";
      default = "zfs";
    };

    nasIP = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "IP of Network Attached Storage.";
    };

    notificationEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Email receiving all notifications from the machine.";
    };

    notificationSender = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Email sender of all notification emails.";
    };

    openPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      description = "List of additionally opened ports on system.";
      default = [ ];
    };

    primaryUser = lib.mkOption {
      type = lib.types.str;
      description = "Primary unprivileged user login";
      example = "bob";
    };

    primaryUserPasswordSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret path for primary user password.";
      example = "users/bob/password";
    };

    purpose = lib.mkOption {
      type = lib.types.str;
      description = "Purpose of the given machine, to be displayed in motd.";
      example = "NAS Server";
    };

    rootDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Root domain of all exposed services (mostly nginx Vhosts).";
    };

    swapSize = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Swap size with unit";
      example = "4G";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      description = "Global theme used for all the desktop apps";
      example = "nord";
      default = "catppuccin-mocha";
    };

    wallpaper = lib.mkOption {
      # type = lib.types.nullOr lib.types.path;
      type = lib.types.coercedTo lib.types.package toString lib.types.path;
      description = "Desktop wallpaper";
      default = ./assets/pixel.png;
    };
  };

  config = {
    programs.nix-index-database.comma.enable = true;

    users.groups.services = { };

    boot.kernelModules = config.mySystem.extraModules;

    environment.enableAllTerminfo = true;

    # more file descriptors
    security.pam.loginLimits = [
      {
        domain = "*";
        item = "nofile";
        type = "-";
        value = "4096";
      }
    ];

    services = {
      udev.extraRules = config.mySystem.extraUdevRules;

      zfs = lib.mkIf (config.mySystem.filesystem == "zfs") {
        autoScrub.enable = true;
        trim.enable = true;
        zed.settings = lib.mkIf config.mySystem.alerts.pushover.enable {
          ZED_PUSHOVER_TOKEN = "$(source ${config.mySystem.alerts.pushover.envFileSopsSecret} && echo $PUSHOVER_API_KEY)";
          ZED_PUSHOVER_USER = "$(source ${config.mySystem.alerts.pushover.envFileSopsSecret} && echo $PUSHOVER_USER_KEY)";
        };
      };
    };

    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) (
        config.mySystem.allowUnfree
        ++ config.home-manager.users."${config.mySystem.primaryUser}".myHomeApps.allowUnfree
      );

    networking.firewall.allowedTCPPorts =
      config.home-manager.users."${config.mySystem.primaryUser}".myHomeApps.openPorts;
    networking.firewall.allowedUDPPorts =
      config.home-manager.users."${config.mySystem.primaryUser}".myHomeApps.openPorts;

    security.sudo = {
      execWheelOnly = true;
      extraConfig = lib.mkAfter ''
        Defaults lecture="never"
        Defaults env_keep += "TERM TERMINFO"
      '';
    };

    stylix = rec {
      enable = true;
      autoEnable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.mySystem.theme}.yaml";
      polarity = (svc.importYAML base16Scheme).variant;
      opacity.terminal = 0.95;
      image = config.mySystem.wallpaper;

      cursor = {
        package = pkgs.catppuccin-cursors.mochaDark;
        name = "catppuccin-mocha-dark-cursors";
        size = 48;
      };

      fonts = {
        serif = {
          package = pkgs.noto-fonts;
          name = "Noto Serif";
        };

        sansSerif = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
        };

        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font Mono";
        };

        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
      };
    };
  };
}
