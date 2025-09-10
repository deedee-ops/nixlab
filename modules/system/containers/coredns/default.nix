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
        image = "registry.k8s.io/coredns/coredns:v1.12.4@sha256:986f04c2e15e147d00bdd51e8c51bcef3644b13ff806be7d2ff1b261d6dfbae1";
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
