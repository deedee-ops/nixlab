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

    crossBuildSystems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of systems, which will be enabled for qemu crossbuild on this machine.";
      example = [ "aarch64-linux" ];
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
        "btrfs"
        "zfs"
      ];
      description = "Global filesystem for the system disks. As a rule of thumb - use 'ext4' for VMs, 'zfs' for servers and 'btrfs' for desktops.";
      default = "zfs";
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

    primaryUserExtraDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Extra directories on filesystem to be created for user.";
      default = [ ];
      example = [ "/media" ];
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

    recoveryMode = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Provision nix into recovery mode - meaning no services dependant on backups will be started,
        to avoid interference. Restore all backups, and then reprovision nix with this flag disabled.
      '';
      default = false;
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

    supportedTerminals = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "alacritty"
        "ghostty"
        "kitty"
      ];
      internal = true;
    };
  };

  config = {
    programs.nix-index-database.comma.enable = true;

    users.groups.services = { };

    boot = {
      kernelModules = config.mySystem.extraModules;
      binfmt.emulatedSystems = config.mySystem.crossBuildSystems;
    };

    # terminfo for terminals I use
    environment.systemPackages = builtins.map (
      term: pkgs."${term}".terminfo
    ) config.mySystem.supportedTerminals;

    # more file descriptors
    security.pam.loginLimits = [
      {
        domain = "*";
        item = "nofile";
        type = "-";
        value = "4096";
      }
    ];

    services.udev.extraRules = config.mySystem.extraUdevRules;

    networking.firewall.allowedTCPPorts =
      config.home-manager.users."${config.mySystem.primaryUser}".myHomeApps.openPorts;
    networking.firewall.allowedUDPPorts =
      config.home-manager.users."${config.mySystem.primaryUser}".myHomeApps.openPorts;

    security.sudo = {
      execWheelOnly = true;
      extraConfig = lib.mkAfter ''
        Defaults lecture="never"
        Defaults env_keep += "HOME PATH XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME TERM TERMINFO ZDOTDIR"
      '';
    };

    stylix = rec {
      enable = true;
      autoEnable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.mySystem.theme}.yaml";
      polarity = (svc.importYAML base16Scheme).variant;
      opacity.terminal = 0.95;
      image = config.mySystem.wallpaper;
      targets.font-packages.enable = true;

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
