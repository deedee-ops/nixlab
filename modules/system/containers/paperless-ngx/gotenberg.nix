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
        image = "docker.io/gotenberg/gotenberg:8.29.1@sha256:36c925776fa0db0fd1030408d131fde7ac3453027a559883555155b72adb16a7";
      };
    };
  };
}
