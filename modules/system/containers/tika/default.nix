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
        image = "ghcr.io/deedee-ops/tika:3.1.0@sha256:47265b4812b0408f74a85c47c8f1f36b596b50a293b4fb7d0bad35110ec055d1";
      };
    };
  };
}
