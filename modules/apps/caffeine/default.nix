{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.caffeine;
in
{
  options.myHomeApps.caffeine = {
    enable = lib.mkEnableOption "caffeine";
  };

  config = lib.mkIf cfg.enable {
    # in awesome service runs too early and caffeine breaks
    services.caffeine.enable = osConfig.mySystem.xorg.windowManager != "awesome";

    myHomeApps.awesome.autorun = [ "${lib.getExe pkgs.caffeine-ng}" ];
  };
}
