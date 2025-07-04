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
    virtualisation.oci-containers.containers.crypt-mysql = svc.mkContainer {
      cfg = {
        image = "registry.${config.mySystem.rootDomain}/deedee/crypt-mysql:5.1.73";
        dependsOn = lib.optionals config.mySystemApps.registry.enable [ "registry" ];
      };
      opts = {
        customNetworks = [ "crypt" ];
        readOnlyRootFilesystem = false;
      };
    };
  };
}
