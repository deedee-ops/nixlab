{ lib, ... }:
{
  imports = [
    ./gotenberg.nix
    ./paperless-ngx.nix
  ];

  options.mySystemApps.paperless-ngx = {
    enable = lib.mkEnableOption "paperless-ngx container";
    backup = lib.mkEnableOption "postgresql and data backup" // {
      default = true;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/paperless-ngx";
    };
    sopsSecretPrefix = lib.mkOption {
      type = lib.types.str;
      description = "Prefix for sops secret, under which all ENVs will be appended.";
      default = "system/apps/paperless-ngx/env";
    };
  };
}
