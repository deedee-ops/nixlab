_: {
  flake.nixosModules.features-nixos-openconnect =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.nixos.openconnect;
    in
    {
      options.features.nixos.openconnect = {
        keepaliveHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "Host to curl periodically to keep connection alive. Disabled if null.";
          default = null;
          example = "http://10.42.67.69";
        };
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
        };
      };

      config = {
        sops.secrets =
          lib.genAttrs [ "features/nixos/openconnect/config" "features/nixos/openconnect/password" ]
            (_: {
              sopsFile = cfg.sopsSecretsFile;
            });
        systemd = {
          services.openconnect = {
            description = "OpenConnect Interface";
            requires = [ "network-online.target" ];
            after = [
              "network.target"
              "network-online.target"
            ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${lib.getExe pkgs.openconnect} --config=${
                config.sops.secrets."features/nixos/openconnect/config".path
              }";
              StandardInput = "file:${config.sops.secrets."features/nixos/openconnect/password".path}";
              ProtectHome = true;
            };
          };

          # poor mans keepalive
          services.openconnect-keepalive = lib.mkIf (cfg.keepaliveHost != null) {
            script = ''
              ${lib.getExe pkgs.curl} -s ${cfg.keepaliveHost}
            '';
            serviceConfig = {
              Type = "oneshot";
              User = "root";
            };
          };
          timers.openconnect-keepalive = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "*:0/5";
              Persistent = true;
              Unit = "openconnect-keepalive.service";
            };
          };
        };
      };
    };
}
