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
        image = "ghcr.io/deedee-ops/gotenberg:8.17.1@sha256:fa8f5417f82625bd7c4c9c041fa93d18584e0ad86581921a31d96c424b1f16a1";
      };
    };
  };
}
