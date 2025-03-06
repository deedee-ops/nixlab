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
        image = "ghcr.io/deedee-ops/gotenberg:8.17.3@sha256:a51da964fb6ecb2938597de1149cc668e61d074e1cec1484f78ea3d415157245";
      };
    };
  };
}
