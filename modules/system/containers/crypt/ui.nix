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
    virtualisation.oci-containers.containers.crypt-ui = svc.mkContainer {
      cfg = {
        image = "registry.${config.mySystem.rootDomain}/deedee/crypt-ui:0.10.9";
        dependsOn = [
          "crypt"
        ];
        environment = {
          CRYPT_HOST = "crypt";
        };
        extraOptions = [
          "--cap-add=CAP_DAC_OVERRIDE"
        ];
      };
      opts = {
        customNetworks = [
          config.mySystemApps.docker.network.private.name
          "crypt"
        ];
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.crypt-ui = svc.mkNginxVHost {
        host = "crypt";
        proxyPass = "http://crypt-ui.docker:3000";
      };
      nginx.virtualHosts.crypt-items = svc.mkNginxVHost {
        host = "~^.*\\.crypt\\.${builtins.replaceStrings [ "." ] [ "\\." ] config.mySystem.rootDomain}$";
        useHostAsServerName = true;
        useACMEHost = "wildcard.crypt.${config.mySystem.rootDomain}";
        proxyPass = "http://crypt-ui.docker:8080";
        customCSP = "disable";
      };
    };

    mySystemApps.homepage = {
      services.Apps.Crypt = svc.mkHomepage "crypt" // {
        icon = "https://upload.wikimedia.org/wikipedia/en/6/61/Vault_Boy_artwork.png";
        description = "Nostalgia crypt";
      };
    };
  };
}
