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
        image = "docker.io/gotenberg/gotenberg:8.30.1@sha256:206a6c708fc6d05257367d9ac902d6c56c50d2e3284d0596ea000814ef97f22c";
      };
    };
  };
}
