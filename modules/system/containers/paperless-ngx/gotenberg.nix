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
        image = "ghcr.io/deedee-ops/gotenberg:8.17.2@sha256:fec8d9f7bd5d7801a1506ecf08b20747d4e0c7055d0587a2303df99969cd8fa4";
      };
    };
  };
}
