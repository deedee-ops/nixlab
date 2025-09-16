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
        image = "docker.io/apache/tika:3.2.3.0@sha256:c0154cb95587cde64be74f35ada1a2bd7892219f3f0ac3c9dc6cab34046b3573";
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
    };
  };
}
