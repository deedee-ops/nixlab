{
  config,
  pkgs,
  ...
}:
let
  inherit (config.mySystem) primaryUser primaryUserPasswordSopsSecret;
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
    create-media = {
      deps = [ "users" ];
      text = ''
        mkdir -p /media || true
        chown ${primaryUser}:users /media
      '';
    };
  };
}
