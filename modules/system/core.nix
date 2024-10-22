{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  nerdfonts = pkgs.nerdfonts.override {
    fonts = [
      "FiraMono"
      "JetBrainsMono"
    ];
  };
in
{
  options.mySystem = {
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

    timezone = lib.mkOption {
      type = lib.types.str;
      description = "Timezone for all services.";
      default = "Europe/Warsaw";
    };

    wallpaper = lib.mkOption {
      # type = lib.types.nullOr lib.types.path;
      type = lib.types.coercedTo lib.types.package toString lib.types.path;
      description = "Desktop wallpaper";
      default = ./assets/pixel.png;
    };
  };

  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 30d";
      };
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users = [
          "root"
          "@wheel"
          config.mySystem.primaryUser
        ];
        use-xdg-base-directories = true;
      };
    };

    programs.nix-index-database.comma.enable = true;

    users.groups.services = { };

    stylix = rec {
      enable = true;
      autoEnable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.mySystem.theme}.yaml";
      polarity = (svc.importYAML base16Scheme).variant;
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
          package = nerdfonts;
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
