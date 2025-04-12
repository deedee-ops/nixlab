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
        image = "ghcr.io/deedee-ops/gotenberg:8.20.0@sha256:f521de00faefc3b3c6b2658e371c7cc91e8a35a13162b536b383d501ab1e3c25";
      };
    };
  };
}
