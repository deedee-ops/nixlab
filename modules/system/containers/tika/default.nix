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
        image = "ghcr.io/deedee-ops/tika:3.0.0@sha256:019f013bcd437b88cc492197165365d01f4b7aa2861078488a0fa97967956d00";
      };
    };
  };
}
