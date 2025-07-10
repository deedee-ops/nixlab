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
        image = "docker.io/apache/tika:3.2.1.0@sha256:df12b41af58c9833e60bdc231ffc4b59f5b7a83bfe2d63e3dc7aab7da923abba";
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
    };
  };
}
