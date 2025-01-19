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

        image = "ghcr.io/netbox-community/netbox:v4.2.2-3.1.0@sha256:707e242b567387aa7eccfbfc5c07d781db7bde806cc41d34062d765316f09422";
        dependsOn = [ "netbox" ];
        user = "unit:root";

        cmd = [
          "/opt/netbox/housekeeping.sh"
        ];
      };
    };
  };
}
