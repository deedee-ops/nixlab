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
        image = "ghcr.io/flaresolverr/flaresolverr:v3.3.24@sha256:72e5a8bc63899ebeeb6bc0aece2b05a8d725c8a518aa30c610a8d61bb50303e1";
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
