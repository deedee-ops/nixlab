{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.photon;
in
{
  options.mySystemApps.photon = {
    enable = lib.mkEnableOption "photon container";
    geodataPath = lib.mkOption {
      type = lib.types.str;
      description = ''
        Path to directory containing geodata.
        Needs at least 500GB of space (200+GB for data, and same amount for copy when doing parallel update).
      '';
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Make photo API exposed only for docker containers, without attaching it to reverse proxy.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.photon = svc.mkContainer {
      cfg = {
        image = "ghcr.io/rtuszik/photon-docker:1.3.0@sha256:f7fddc6bf92107e2531bd76de4a9dbe5f0b65d7411e2fc02253be92fd7cb20bb";
        environment = {
          UPDATE_STRATEGY = "PARALLEL";
          UPDATE_INTERVAL = "30d";
        };
        volumes = [ "${cfg.geodataPath}:/photon/data" ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_DAC_OVERRIDE"
          "--cap-add=CAP_FOWNER"
          "--cap-add=CAP_SETGID"
          "--cap-add=CAP_SETUID"
        ];
      };
      opts = {
        # fetching geo data
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };

    services = lib.mkIf (!cfg.internal) {
      nginx.virtualHosts.photon = svc.mkNginxVHost {
        host = "photon";
        proxyPass = "http://photon.docker:2322";
        useAuthelia = false;
      };
    };
  };
}
