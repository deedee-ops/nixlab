_: {
  flake.nixosModules.features-nixos-tailscale =
    { config, lib, ... }:
    let
      cfg = config.features.nixos.tailscale;
    in
    {
      options.features.nixos.tailscale = {
        acceptDNS = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Accept DNS configuration (MagicDNS) from the tailnet.";
        };
        acceptRoutes = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Accept subnet routes advertised by tailnet routers (e.g. the home LAN).";
        };
        advertiseTags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Tags advertised by this node. Tagged nodes have key expiry disabled by default.";
          example = [ "tag:hatch" ];
        };
        sopsSecretsFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Path to sopsfile containing `features/nixos/tailscale/authKey` (auth key or OAuth client secret),
            used to join the tailnet unattended. If null, the node has to be logged in manually with `tailscale up`.
          '';
        };
      };

      config = {
        sops.secrets = lib.mkIf (cfg.sopsSecretsFile != null) {
          "features/nixos/tailscale/authKey" = {
            sopsFile = cfg.sopsSecretsFile;
          };
        };

        services.tailscale = {
          enable = true;
          disableTaildrop = true;
          openFirewall = true;
          # loose reverse path filtering, otherwise replies from subnet routes get dropped
          useRoutingFeatures = if cfg.acceptRoutes then "client" else "none";

          authKeyFile = lib.mkIf (
            cfg.sopsSecretsFile != null
          ) config.sops.secrets."features/nixos/tailscale/authKey".path;
          # only used when authKeyFile is an OAuth client secret (OAuth nodes are ephemeral by default)
          authKeyParameters = {
            ephemeral = false;
            preauthorized = true;
          };

          extraUpFlags = lib.optional (
            cfg.advertiseTags != [ ]
          ) "--advertise-tags=${lib.concatStringsSep "," cfg.advertiseTags}";
          extraSetFlags = [
            "--accept-dns=${lib.boolToString cfg.acceptDNS}"
            "--accept-routes=${lib.boolToString cfg.acceptRoutes}"
            "--operator=${config.features.nixos.user.name}"
          ];
        };
      };
    };
}
