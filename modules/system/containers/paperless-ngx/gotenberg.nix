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
        image = "ghcr.io/deedee-ops/gotenberg:8.18.0@sha256:98810d165377819a5e1e78c76aff2ae0b76efa195e4f1993c113ae59e4f8cace";
      };
    };
  };
}
