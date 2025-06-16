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
        image = "registry.k8s.io/coredns/coredns:v1.12.2@sha256:af8c8d35a5d184b386c4a6d1a012c8b218d40d1376474c7d071bb6c07201f47d";
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
