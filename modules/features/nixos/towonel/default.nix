_: {
  flake.nixosModules.features-nixos-towonel =
    { config, lib, ... }:
    let
      cfg = config.features.nixos.towonel;
    in
    {
      options.features.nixos.towonel = {
        publicHost = lib.mkOption {
          type = lib.types.str;
          description = "Public Host advertised to the clients.";
          example = "towonel.example.com";
        };
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
        };
      };

      config = {
        sops = {
          secrets =
            lib.genAttrs
              [
                "features/nixos/towonel/hubKek"
                "features/nixos/towonel/inviteHashKey"
                "features/nixos/towonel/operatorApiKey"
              ]
              (_: {
                sopsFile = cfg.sopsSecretsFile;
              });
          templates."towonel.env".content = ''
            TOWONEL_INVITE_HASH_KEY=${config.sops.placeholder."features/nixos/towonel/inviteHashKey"}
            TOWONEL_HUB_OPERATOR_API_KEY=${config.sops.placeholder."features/nixos/towonel/operatorApiKey"}
            TOWONEL_OPERATOR_KEY=${config.sops.placeholder."features/nixos/towonel/operatorApiKey"}
            TOWONEL_HUB_KEK=${config.sops.placeholder."features/nixos/towonel/hubKek"}
          '';
        };

        virtualisation.oci-containers.containers.towonel = {
          image = "codeberg.org/towonel/towonel-node:latest";
          extraOptions = [ "--network=host" ];
          volumes = [
            "/var/lib/towonel:/data"
          ];
          environmentFiles = [ config.sops.templates."towonel.env".path ];
          environment = {
            TOWONEL_EDGE_ADVERTISED_ADDRESSES = "${cfg.publicHost}:4443";
            TOWONEL_EDGE_LISTEN_ADDR = "0.0.0.0:4443";
            TOWONEL_HUB_PUBLIC_URL = "https://${cfg.publicHost}:4443";
            TOWONEL_HUB_TLS_ACME_STAGING = "true";
            TOWONEL_HUB_TLS_ACME_EMAIL = "acme@ajgon.ovh";
          };
        };

        networking.firewall = {
          allowedTCPPorts = [
            4443
            8443
            5555
          ];
          allowedUDPPorts = [
            51820
          ];
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/towonel 0750 10001 10001 -"
        ];
      };
    };
}
