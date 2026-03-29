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
        image = "docker.io/gotenberg/gotenberg:8.29.0@sha256:a4c25548ac7a442e6f0126f6835d5eb17b23f2ab6bf4f6c821e3a16ae5664930";
      };
    };
  };
}
