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
        image = "docker.io/gotenberg/gotenberg:8.30.0@sha256:d3c9e0ed2450c9a4631de6d14b51c75fd6051512c33aa8a6df622f085592c48b";
      };
    };
  };
}
