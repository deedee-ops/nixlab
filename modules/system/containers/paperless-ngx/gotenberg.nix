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
        image = "docker.io/gotenberg/gotenberg:8.28.0@sha256:f172b1ce5ec7516ab9452d33bfe3f198d778d3de39655825aa550f4a33946666";
      };
    };
  };
}
