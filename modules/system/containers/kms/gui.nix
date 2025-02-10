{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.kms;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.kms-gui = svc.mkContainer {
      cfg = {
        image = "11notes/kms-gui:stable@sha256:3776ea2bdec93f9e4f2d80f17c1115467182ea7a721adde7a3b856707f8117b7";
        user = "65000:65000";
        dependsOn = [ "kms-server" ];
        volumes = [ "${cfg.dataDir}:/kms/var" ];

        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
    };

    services = {
      nginx.virtualHosts.kms-gui = svc.mkNginxVHost {
        host = "kms";
        proxyPass = "http://kms-gui.docker:8080";
      };
    };

    mySystemApps.homepage = {
      services.Apps.kms = svc.mkHomepage "kms" // {
        container = "kms-gui";
        description = "KMS activation server";
      };
    };
  };
}
