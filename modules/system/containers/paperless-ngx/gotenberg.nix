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
        image = "docker.io/gotenberg/gotenberg:8.25.1@sha256:f9104080d9a7ecab253fb5ebe75100329cf5699c33ec0448f2ea02d885dfde4b";
      };
    };
  };
}
