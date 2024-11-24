{
  config,
  lib,
  ...
}:
let
  cfg = config.myHardware.openrgb;
in
{
  options.myHardware.openrgb = {
    enable = lib.mkEnableOption "openrgb";
    profile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Path to profile which will be autoapplied on system start.";
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.hardware.openrgb.enable = true;

    systemd.services.apply-openrgb-profile = lib.mkIf (cfg.profile != null) {
      script = ''
        ${lib.getExe config.services.hardware.openrgb.package} -p ${cfg.profile}
      '';
      wantedBy = [ "multi-user.target" ];
    };
  };
}
