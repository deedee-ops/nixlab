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
        image = "docker.io/gotenberg/gotenberg:8.31.0@sha256:f0d86e8a1dbc7b33a5a65cb251d02bb271a48ffa989da3feb5ed7d954fe4d4b3";
      };
    };
  };
}
