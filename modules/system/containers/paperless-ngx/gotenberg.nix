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
        image = "ghcr.io/deedee-ops/gotenberg:8.19.1@sha256:c95458c432772b23f9f390b78f534901c86bbd8c4920fab24c962724a81e86f9";
      };
    };
  };
}
