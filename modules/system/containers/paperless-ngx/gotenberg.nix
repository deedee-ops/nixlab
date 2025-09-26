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
        image = "docker.io/gotenberg/gotenberg:8.23.2@sha256:56c47f7b913f3b978554115a0191c4a9dcc2558f9090f27f3f13f28a7c2f8329";
      };
    };
  };
}
