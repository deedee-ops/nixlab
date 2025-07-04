{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.mySystem) primaryUser primaryUserExtraDirs primaryUserPasswordSopsSecret;
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

  programs.zsh.enable = true;

  system.activationScripts = {
    create-extra-dirs = {
      deps = [ "users" ];
      text = lib.concatStringsSep "\n" (
        builtins.map (extraDir: ''
          mkdir -p ${extraDir} || true
          chown ${primaryUser}:users ${extraDir}
        '') primaryUserExtraDirs
      );
    };
  };
}
