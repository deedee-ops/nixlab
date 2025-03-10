{
  config,
  lib,
  ...
}:
let
  cfg = config.mySystemApps.crypt;
in
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

  config = lib.mkIf cfg.enable {
    mySystemApps.docker.extraNetworks = [
      {
        name = "crypt";
        subnet = "172.29.1.0/24";
        hostIP = "172.29.1.1";
      }
    ];
  };
}
