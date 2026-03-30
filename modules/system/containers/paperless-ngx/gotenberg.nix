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
        image = "docker.io/gotenberg/gotenberg:8.29.1@sha256:d89fe8c26bc230d4551b351e8a6249d4b42bb469289a26486447614a0cecee5d";
      };
    };
  };
}
