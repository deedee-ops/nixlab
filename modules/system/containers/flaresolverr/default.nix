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
        image = "ghcr.io/flaresolverr/flaresolverr:v3.4.0@sha256:ab535d1fef5d7f1654c2756949798442ae4bbecee99d4338128aa137fd8eca0e";
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
