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
        image = "ghcr.io/deedee-ops/gotenberg:8.15.0@sha256:80e78af8cdb53dd42f79e0a9e0fbf27843044a70420a44134b8eb04c6c692a28";
      };
    };
  };
}
