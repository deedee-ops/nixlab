{ config, lib, ... }:
let
  cfg = config.myHomeApps.redshift;
in
{
  options.myHomeApps.redshift = {
    enable = lib.mkEnableOption "redshift";
    latitude = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.str lib.types.float);
      description = ''
        Your current latitude, between `-90.0` and
        `90.0`. Must be provided along with
        longitude.
      '';
      default = null;
    };
    longitude = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.str lib.types.float);
      default = null;
      description = ''
        Your current longitude, between `-180.0` and
        `180.0`. Must be provided along with
        latitude.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.redshift = {
      inherit (cfg) latitude longitude;

      enable = true;
      provider = "manual";
      tray = true;
    };
  };
}
