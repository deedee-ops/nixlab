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
        image = "registry.k8s.io/coredns/coredns:v1.12.1@sha256:e8c262566636e6bc340ece6473b0eed193cad045384401529721ddbe6463d31c";
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
