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
        image = "ghcr.io/deedee-ops/gotenberg:8.17.0@sha256:9ec260af503e2ea31fb0700b3add769f0bfb3be53e3efa857d417d22fe1de959";
      };
    };
  };
}
