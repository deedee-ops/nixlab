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
        image = "ghcr.io/deedee-ops/gotenberg:8.12.0@sha256:4b8d479fbdb893478297e9cf03e4f37791ddc9e9a65e4bc152421224c07a2db9";
      };
    };
  };
}
