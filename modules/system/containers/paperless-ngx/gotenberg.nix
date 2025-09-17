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
        image = "docker.io/gotenberg/gotenberg:8.23.1@sha256:6ae55a47fee9f95541aadb9af5a87548ebcc0603e8f6bf6af01ca82e594a78cc";
      };
    };
  };
}
