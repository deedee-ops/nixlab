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
    virtualisation.oci-containers.containers.netbox = svc.mkContainer {
      cfg = {
        inherit (cfg) environment volumes;

        image = "ghcr.io/netbox-community/netbox:v4.2.2-3.1.0@sha256:51e14595287666bf8e0fc02d9e9aa5c4b54f9d5203257d6618d97ee8ddaa4364";
        user = "unit:root";
      };
      opts = {
        readOnlyRootFilesystem = false;
      };
    };

    services = {
      nginx.virtualHosts.netbox = svc.mkNginxVHost {
        host = "netbox";
        proxyPass = "http://netbox.docker:8080";
        autheliaIgnorePaths = [
          "/api"
        ];
        customCSP = ''
          default-src 'self' 'unsafe-inline' data: blob: wss:;
          img-src 'self' data:;
          object-src 'self' *.${config.mySystem.rootDomain};
          style-src 'self' 'unsafe-inline' data: blob: *.${config.mySystem.rootDomain};
        '';
      };
      postgresqlBackup = lib.mkIf cfg.backup { databases = [ "netbox" ]; };
      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "netbox";
          paths = [ cfg.dataDir ];
        }
      );
    };

    systemd.services.docker-netbox = {
      preStart = lib.mkAfter (
        ''
          mkdir -p "${cfg.dataDir}/config" "${cfg.dataDir}/media" "${cfg.dataDir}/reports" "${cfg.dataDir}/scripts"
          cp -r "${./configuration}/"* "${cfg.dataDir}/config"
          chown -R 999:0 "${cfg.dataDir}/config"
          chown 999:0 "${cfg.dataDir}/media" "${cfg.dataDir}/reports" "${cfg.dataDir}/scripts"
        ''
        + (builtins.concatStringsSep "\n" (
          builtins.map (secret: "chown 999:0 ${config.sops.secrets."${secret}".path}") (
            builtins.filter (secret: lib.strings.hasPrefix "${cfg.sopsSecretPrefix}" secret) (
              builtins.attrNames config.sops.secrets
            )
          )
        ))
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    mySystemApps.homepage = {
      services.Apps.NetBox = svc.mkHomepage "netbox" // {
        description = "Network infra source of truth";
      };
    };
  };
}
