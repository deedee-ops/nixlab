{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.netbox;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.netbox-worker = svc.mkContainer {
      cfg = {
        inherit (cfg) environment volumes;

        image = "ghcr.io/netbox-community/netbox:v4.2.2-3.1.0@sha256:51e14595287666bf8e0fc02d9e9aa5c4b54f9d5203257d6618d97ee8ddaa4364";
        dependsOn = [ "netbox" ];
        user = "unit:root";

        cmd = [
          "/opt/netbox/venv/bin/python"
          "/opt/netbox/netbox/manage.py"
          "rqworker"
        ];
      };
    };
  };
}
