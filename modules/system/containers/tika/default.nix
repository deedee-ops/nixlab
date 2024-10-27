{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.tika;
in
{
  options.mySystemApps.tika = {
    enable = lib.mkEnableOption "tika container";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.tika = svc.mkContainer {
      cfg = {
        image = "ghcr.io/deedee-ops/tika:3.0.0@sha256:ca20827c852caa53607275e8626f5da46781708ebb30b78aad468ad23167cc39";
      };
    };
  };
}
