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
    virtualisation.oci-containers.containers.netbox-housekeeping = svc.mkContainer {
      cfg = {
        inherit (cfg) environment volumes;

        image = "ghcr.io/netbox-community/netbox:v4.2.2-3.1.0@sha256:bd7ec3278178894cf3c0452435fd8a016ef73f5e05b7d9e285258bd4c2f9f201";
        dependsOn = [ "netbox" ];
        user = "unit:root";

        cmd = [
          "/opt/netbox/housekeeping.sh"
        ];
      };
    };
  };
}
