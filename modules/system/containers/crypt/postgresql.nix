{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.crypt;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.crypt-postgresql = svc.mkContainer {
      cfg = {
        image = "registry.${config.mySystem.rootDomain}/deedee/crypt-postgresql:8.4.22";
      };
      opts = {
        customNetworks = [ "crypt" ];
        readOnlyRootFilesystem = false;
      };
    };
  };
}
