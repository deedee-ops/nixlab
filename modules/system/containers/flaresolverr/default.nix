{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.flaresolverr;
in
{
  options.mySystemApps.flaresolverr = {
    enable = lib.mkEnableOption "flaresolverr container";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.flaresolverr = svc.mkContainer {
      cfg = {
        image = "ghcr.io/flaresolverr/flaresolverr:v3.3.25@sha256:68160ec125e5cde23bc45549a443da0da0223cf4f0de7571ed2c6851cf6e1561";
        environment = {
          LOG_LEVEL = "info";
        };
      };
      opts = {
        # for proxying requestes to solve CF captcha
        allowPublic = true;
        readOnlyRootFilesystem = false;
      };
    };
  };
}
