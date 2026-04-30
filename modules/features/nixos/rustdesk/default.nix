_: {
  flake.nixosModules.features-nixos-rustdesk =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.nixos.rustdesk;

      # Runs as root (+ prefix) after systemd creates the StateDirectory symlink,
      # before hbbs/hbbr start. Copies SOPS-decrypted keys into the working directory
      # so the servers pick them up instead of generating new ones.
      copyKeysScript = pkgs.writeShellScript "rustdesk-copy-keys" ''
        ${pkgs.coreutils}/bin/install -m 400 -o rustdesk -g rustdesk \
          ${config.sops.secrets."features/nixos/rustdesk/privateKey".path} \
          /var/lib/rustdesk/id_ed25519
        ${pkgs.coreutils}/bin/install -m 400 -o rustdesk -g rustdesk \
          ${config.sops.secrets."features/nixos/rustdesk/publicKey".path} \
          /var/lib/rustdesk/id_ed25519.pub
      '';
    in
    {
      options.features.nixos.rustdesk = {
        relayHost = lib.mkOption {
          type = lib.types.str;
          description = "Relay Host advertised to the clients.";
          example = "relay.example.com";
        };
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
        };
      };

      config = {
        sops.secrets =
          lib.genAttrs [ "features/nixos/rustdesk/privateKey" "features/nixos/rustdesk/publicKey" ]
            (_: {
              owner = "rustdesk";
              group = "rustdesk";
              restartUnits = [
                "rustdesk-signal.service"
                "rustdesk-relay.service"
              ];
              sopsFile = cfg.sopsSecretsFile;
            });

        services.rustdesk-server = {
          enable = true;
          openFirewall = true;
          signal.relayHosts = [ cfg.relayHost ];
        };

        systemd.services = {
          rustdesk-signal.serviceConfig.ExecStartPre = lib.mkBefore [ "+${copyKeysScript}" ];
          rustdesk-relay.serviceConfig.ExecStartPre = lib.mkBefore [ "+${copyKeysScript}" ];
        };
      };
    };
}
