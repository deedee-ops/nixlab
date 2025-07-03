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
        image = "docker.io/gotenberg/gotenberg:8.21.1@sha256:91486863744f7420ca985ee6cef7c216910e40faffd378f3da7c0fad724d01ba";
      };
    };
  };
}
