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
    virtualisation.oci-containers.containers.crypt = svc.mkContainer {
      cfg = {
        image = "registry.${config.mySystem.rootDomain}/deedee/crypt:1.0.0";
        dependsOn = [
          "crypt-mysql"
          "crypt-postgresql"
        ];
        environment = {
          MYSQL_HOST = "crypt-mysql";
          POSTGRESQL_HOST = "crypt-postgresql";
        };
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_FSETID"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
        ];
      };
      opts = {
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.crypt-items = svc.mkNginxVHost {
        host = "~^.*\\.crypt\\.${builtins.replaceStrings [ "." ] [ "\\." ] config.mySystem.rootDomain}$";
        useHostAsServerName = true;
        useACMEHost = "wildcard.crypt.${config.mySystem.rootDomain}";
        useAuthelia = false;
        proxyPass = "http://crypt.docker:80";
        customCSP = "disable";
      };
    };
  };
}
