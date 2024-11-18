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
        image = "ghcr.io/deedee-ops/gotenberg:8.14.0@sha256:859fd3496b804848cbe5a25e1c7ebef22365ddaea092d06c8ca6569150f0e6e0";
      };
    };
  };
}
