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
        image = "ghcr.io/deedee-ops/gotenberg:8.15.3@sha256:63245f2bbb1c545870db91ab768b5dbc8885d718b27cf5f469c9e3bbe4205a30";
      };
    };
  };
}
