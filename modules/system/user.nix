{ config, pkgs, ... }:
let
  inherit (config.mySystem) primaryUser;
in
{
  users.mutableUsers = true;

  users.users."${primaryUser}" = {
    isNormalUser = true;
    description = "${primaryUser}";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  system.activationScripts = {
    create-media = {
      deps = [ "users" ];
      text = ''
        mkdir -p /media || true
        chown ${primaryUser}:users /media
      '';
    };
  };
}
