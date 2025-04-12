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
        image = "ghcr.io/deedee-ops/gotenberg:8.20.1@sha256:5977dbab97efdf16f28af22c259fab475b2dc32c1003bca3e134ac457d1b470d";
      };
    };
  };
}
