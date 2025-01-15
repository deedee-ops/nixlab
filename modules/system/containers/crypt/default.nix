{
  lib,
  ...
}:
{
  imports = [
    ./crypt.nix
    ./mysql.nix
    ./postgresql.nix
  ];

  options.mySystemApps.crypt = {
    enable = lib.mkEnableOption "crypt container";
  };
}
