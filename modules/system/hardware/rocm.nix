{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHardware.rocm;
in
{
  options.myHardware.rocm = {
    enable = lib.mkEnableOption "rocm";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.extraPackages = [
      pkgs.rocmPackages.clr.icd
      pkgs.rocmPackages.clr
      pkgs.rocmPackages.rocminfo
      pkgs.rocmPackages.rocm-runtime
    ];
    # This is necesery because many programs hard-code the path to hip
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  };
}
