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
        image = "ghcr.io/flaresolverr/flaresolverr:v3.4.6@sha256:7962759d99d7e125e108e0f5e7f3cdbcd36161776d058d1d9b7153b92ef1af9e";
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
