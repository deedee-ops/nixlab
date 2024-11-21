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
        image = "ghcr.io/deedee-ops/gotenberg:8.14.1@sha256:dd3bcbedd408ec1a7411aaef55e5e9305778b74363d78ef3f7a652a3d26bfdab";
      };
    };
  };
}
