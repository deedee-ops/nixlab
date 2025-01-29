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
        image = "ghcr.io/deedee-ops/gotenberg:8.16.0@sha256:9685f51ebec9dca7f65e2846235d3b3a933a607825d2176c63061fec07d9d3fb";
      };
    };
  };
}
