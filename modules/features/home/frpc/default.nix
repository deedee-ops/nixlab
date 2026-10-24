_: {
  flake.homeModules.features-home-frpc =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.home.frpc;

      # frps presents an openbao-issued certificate, so trust only the homelab roots.
      caFile = pkgs.writeText "homelab-ca.crt" (
        builtins.readFile ../../../../assets/ca-ec384.crt
        + builtins.readFile ../../../../assets/ca-rsa4096.crt
      );

      share = pkgs.writeShellApplication {
        name = "share";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.frp
          pkgs.jq
        ];
        text = ''
          FRPC_SERVER_ADDR=${lib.escapeShellArg cfg.serverAddr}
          FRPC_SERVER_PORT=${toString cfg.serverPort}
          FRPC_CA_FILE=${caFile}
          FRPC_TOKEN_FILE=${lib.escapeShellArg config.sops.secrets."features/home/frpc/token".path}
          SHARE_DOMAIN=${lib.escapeShellArg cfg.shareDomain}

          ${builtins.readFile ./share.sh}
        '';
      };
    in
    {
      options.features.home.frpc = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
        serverAddr = lib.mkOption {
          type = lib.types.str;
          description = "frps control endpoint, also the name its TLS certificate is checked against";
          default = "frp.ajgon.casa";
        };
        serverPort = lib.mkOption {
          type = lib.types.port;
          description = "frps control port";
          default = 7000;
        };
        shareDomain = lib.mkOption {
          type = lib.types.str;
          description = "Public hostname routed by envoy-external to the frps vhost";
          default = "share.ajgon.casa";
        };
      };

      config = {
        sops.secrets."features/home/frpc/token" = {
          sopsFile = cfg.sopsSecretsFile;
        };
        home.packages = [ share ];
      };
    };
}
