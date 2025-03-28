{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.paperless-ngx;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.gotenberg = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/gotenberg:8.19.0@sha256:89f0613ee65f1d6fa9b63e0e586d524cd94f62fcab9bbfdb86ea32c9902a519d";
      };
    };
  };
}
