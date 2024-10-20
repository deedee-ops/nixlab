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
    enable = lib.mkEnableOption "coredns container" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.coredns = svc.mkContainer {
      cfg = {
        image = "registry.k8s.io/coredns/coredns:v1.11.3@sha256:9caabbf6238b189a65d0d6e6ac138de60d6a1c419e5a341fbbb7c78382559c6e";
        cmd = [
          "-conf"
          "/etc/coredns/Corefile"
        ];
        volumes = [ "${corefile}:/etc/coredns/Corefile:ro" ];

        extraOptions = [ "--cap-add=NET_BIND_SERVICE" ];

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
