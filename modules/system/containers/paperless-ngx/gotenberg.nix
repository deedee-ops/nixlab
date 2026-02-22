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
        image = "docker.io/gotenberg/gotenberg:8.27.0@sha256:d71ab8c13b6bd47c7bc81195082005dfb17eaa75e8b1fadd347a64ee66ed98d5";
      };
    };
  };
}
