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
        image = "docker.io/gotenberg/gotenberg:8.25.0@sha256:e304e45acee3c400f8ef76afa195c76b1d0eaf0ab6fe9651e305067ab6a1560c";
      };
    };
  };
}
