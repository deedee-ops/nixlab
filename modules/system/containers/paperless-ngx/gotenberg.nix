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
        image = "ghcr.io/deedee-ops/gotenberg:8.15.1@sha256:afd4ec4072b29a26b6696026110066c478747da5d42f5bf0557d663138892562";
      };
    };
  };
}
