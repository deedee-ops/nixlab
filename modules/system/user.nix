{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.mySystem) primaryUser primaryUserExtraDirs primaryUserPasswordSopsSecret;

  primaryUserHomeDir = config.home-manager.users."${config.mySystem.primaryUser}".home.homeDirectory;
in
{
  sops.secrets."${primaryUserPasswordSopsSecret}".neededForUsers = true;

  users = {
    users."${primaryUser}" = {
      isNormalUser = true;
      description = "${primaryUser}";
      extraGroups = [
        "input"
        "networkmanager"
        "video"
        "wheel"
      ];
      shell = pkgs.zsh;
      hashedPasswordFile = config.sops.secrets."${primaryUserPasswordSopsSecret}".path;
    };
  };

  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };

  system.activationScripts = {
    # when using impermanence, .cache and .local symlinks must be created before even home-manager kicks in
    # otherwise it will silently fail
    cache-local = lib.mkIf config.mySystem.impermanence.enable {
      deps = [ "users" ];
      text = ''
        mkdir -p "/home/${config.mySystem.primaryUser}"
        chown ${primaryUser}:users "/home/${config.mySystem.primaryUser}"
        ln -sf "${config.mySystem.impermanence.persistPath}${primaryUserHomeDir}/.cache" "${primaryUserHomeDir}/.cache";
        ln -sf "${config.mySystem.impermanence.persistPath}${primaryUserHomeDir}/.local" "${primaryUserHomeDir}/.local";
      '';
    };
    create-extra-dirs = {
      deps = [ "users" ];
      text = lib.concatStringsSep "\n" (
        builtins.map (extraDir: ''
          mkdir -p ${extraDir} || true
          chown ${primaryUser}:users "${extraDir}"
        '') primaryUserExtraDirs
      );
    };
  };

  # preserve primary user home directory ownership
  systemd = {
    services."preserve-${primaryUser}-home-ownership" = {
      script =
        if config.mySystem.impermanence.enable then
          ''
            chown -R ${primaryUser}:users ${config.mySystem.impermanence.persistPath}${primaryUserHomeDir}
          ''
        else
          ''
            chown -R ${primaryUser}:users ${primaryUserHomeDir}
          '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
    timers."preserve-${primaryUser}-home-ownership" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5";
        Persistent = true;
        Unit = "preserve-${primaryUser}-home-ownership.service";
      };
    };
  };
}
