{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.coredns;
  corefile = pkgs.writeText "Corefile" (builtins.readFile ./Corefile);
in
{
  options.mySystemApps.coredns = {
    enable = lib.mkEnableOption "coredns container";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.coredns = svc.mkContainer {
      cfg = {
        image = "registry.k8s.io/coredns/coredns:v1.14.1@sha256:82b57287b29beb757c740dbbe68f2d4723da94715b563fffad5c13438b71b14a";
        cmd = [
          "-conf"
          "/etc/coredns/Corefile"
        ];
        volumes = [ "${corefile}:/etc/coredns/Corefile:ro" ];

        extraOptions = [ "--cap-add=CAP_NET_BIND_SERVICE" ];

        # using 5353 may break mDNS
        ports = [ "5533:53/udp" ];
      };
      opts = {
        # to expose port to host, public network must be used
        allowPublic = true;
      };
    };
  };
}
