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
        image = "ghcr.io/deedee-ops/gotenberg:8.13.0@sha256:29d450c47290ba4f2656b2f311c1e59545d9ce0ec0561ec9ee6c3cdfd1db5cc5";
      };
    };
  };
}
