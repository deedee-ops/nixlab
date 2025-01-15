{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./crypt.nix
    ./mysql.nix
    ./postgresql.nix
    ./ui.nix
  ];

  options.mySystemApps.crypt = {
    enable = lib.mkEnableOption "crypt container";
  };

  config = {
    systemd.services.docker.postStart =
      let
        dockerBin = lib.getExe pkgs."${config.virtualisation.oci-containers.backend}";
      in
      lib.mkAfter ''
        ${dockerBin} network inspect crypt >/dev/null 2>&1 || ${dockerBin} network create crypt --subnet 172.29.1.0/24 --internal
      '';
  };
}
