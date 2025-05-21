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
        image = "ghcr.io/deedee-ops/gotenberg:8.21.0@sha256:a1f63dfec9e113b2329b697a2d7b87197edddcc60d6ece87e3e96e99d1281a71";
      };
    };
  };
}
