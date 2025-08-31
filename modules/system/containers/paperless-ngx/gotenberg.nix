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
        image = "docker.io/gotenberg/gotenberg:8.23.0@sha256:3e9d970c395dfd7f0f98fd8da5adc01dab6bf95881d8d232f77a9feafe6d4977";
      };
    };
  };
}
