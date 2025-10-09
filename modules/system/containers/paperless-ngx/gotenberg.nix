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
        image = "docker.io/gotenberg/gotenberg:8.24.0@sha256:b116a40a1c24917e2bf3e153692da5acd2e78e7cd67e1b2d243b47c178f31c90";
      };
    };
  };
}
