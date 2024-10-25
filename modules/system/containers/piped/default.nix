{ lib, ... }:
{
  imports = [
    ./backend.nix
    ./frontend.nix
    ./proxy.nix
  ];

  options.mySystemApps.piped = {
    enable = lib.mkEnableOption "piped container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/piped/env";
    };
  };
}
