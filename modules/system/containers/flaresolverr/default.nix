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
        image = "ghcr.io/flaresolverr/flaresolverr:v3.4.3@sha256:057eedf25a22905685c55be78b2dd70bcd617a921384cd17cb3f4e8901753331";
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
