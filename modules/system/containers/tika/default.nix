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
        image = "docker.io/apache/tika:3.2.0.0@sha256:c01b700def0f3020265ec4072ed37e98b5f1f3aa7ee5f9a27e2eb3e88a3561d8";
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
    };
  };
}
