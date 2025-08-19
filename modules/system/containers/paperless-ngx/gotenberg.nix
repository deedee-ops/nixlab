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
        image = "docker.io/gotenberg/gotenberg:8.22.0@sha256:91035c5041e7f986ae89d0e9f1783233dbae4254b19a33f954288466de5d150f";
      };
    };
  };
}
