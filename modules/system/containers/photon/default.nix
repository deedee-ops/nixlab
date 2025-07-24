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
        image = "ghcr.io/rtuszik/photon-docker:0.7.2@sha256:6cf6d57e1d85766cc2ef79bac16b039e3bde6e0888af9d0e32ff023db7588391";
        environment = {
          UPDATE_STRATEGY = "PARALLEL";
          UPDATE_INTERVAL = "30d";
        };
        volumes = [ "${cfg.geodataPath}:/photon/photon_data" ];
        extraOptions = [
          "--cap-add=CAP_CHOWN"
          "--cap-add=CAP_FOWNER"
          "--cap-add=CAP_DAC_OVERRIDE"
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
