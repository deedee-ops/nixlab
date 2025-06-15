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
        image = "ghcr.io/deedee-ops/gotenberg:8.21.1@sha256:9c2e1c5a62f3788ad4c2a6190da17aa8eea8bbf1185e489b4b6660d92916394e";
      };
    };
  };
}
