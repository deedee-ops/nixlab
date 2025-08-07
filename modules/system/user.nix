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
  environment.etc."zshenv.local".text = ''
    if [ "$USER" = "${config.mySystem.primaryUser}" ]; then
      source ${config.home-manager.users."${config.mySystem.primaryUser}".xdg.configHome}/zsh/.zshenv
    fi
  '';

  system.activationScripts = {
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
