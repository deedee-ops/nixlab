{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.tika;
in
{
  options.mySystemApps.tika = {
    enable = lib.mkEnableOption "tika container";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.tika = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/tika:3.0.0@sha256:359b5dc8d6d4c0b05f0637e696718c475202b2dda16cf5c22075dab12c0d3242";
      };
    };
  };
}
