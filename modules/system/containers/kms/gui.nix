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
        image = "11notes/kms-gui:stable@sha256:6e4cd21ef853f88c7964f845309713712d546e9d604171c8deb6582480100d70";
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
