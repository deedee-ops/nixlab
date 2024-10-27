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
    virtualisation.oci-containers.containers.tika = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/tika:2.9.2@sha256:b56d5a88ea693adfc605b8772adb47fce5fba1fec21da8fefcc9678b7734bae0";
      };
    };
  };
}
