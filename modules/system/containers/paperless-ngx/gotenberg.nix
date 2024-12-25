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
        image = "ghcr.io/deedee-ops/gotenberg:8.15.2@sha256:f83f4ee6e930d9e09d815ff0a1d2e1254e8f640db6e23eb578fdfaca09a30a0a";
      };
    };
  };
}
