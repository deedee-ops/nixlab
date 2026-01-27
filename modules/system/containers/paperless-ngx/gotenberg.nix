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
        image = "docker.io/gotenberg/gotenberg:8.26.0@sha256:328551506b3dec3ff6381dd47e5cd72a44def97506908269e201a8fbfa1c12c0";
      };
    };
  };
}
