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
        image = "docker.io/apache/tika:3.2.2.0@sha256:031530a4b81f37454631ce9352b07cedfd03d83c875b05677d80bff6958d11ff";
        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
    };
  };
}
