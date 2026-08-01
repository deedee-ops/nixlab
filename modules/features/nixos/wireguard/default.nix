_: {
  flake.nixosModules.features-nixos-wireguard =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.nixos.wireguard;
    in
    {
      options.features.nixos.wireguard = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };

      config = {
        sops.secrets = lib.genAttrs [ "features/nixos/wireguard/config" ] (_: {
          sopsFile = cfg.sopsSecretsFile;
          path = "/etc/wireguard/wg0.conf";
        });

        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "wg-toggle";
            runtimeInputs = with pkgs; [
              systemd
              libnotify
            ];
            text = ''
              if systemctl is-active --quiet wg-quick-wg0; then
                active=1
              else
                active=0
              fi

              if [ "''${1:-}" = "status" ]; then
                if [ "$active" = 1 ]; then
                  notify-send "WireGuard" "Wireguard is connected"
                else
                  notify-send "WireGuard" "Wireguard is disconnected"
                fi
                exit 0
              fi

              if [ "$active" = 1 ]; then
                systemctl stop wg-quick-wg0 && notify-send "WireGuard" "wg0 disconnected"
              else
                systemctl start wg-quick-wg0 && notify-send "WireGuard" "wg0 connected"
              fi
            '';
          })
        ];

        networking = {
          firewall.checkReversePath = false;
          networkmanager.unmanaged = [ "interface-name:wg0" ];
          wg-quick.interfaces.wg0 = {
            autostart = false;
            configFile = config.sops.secrets."features/nixos/wireguard/config".path;
          };
        };

        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "wg-quick-wg0.service" &&
                subject.isInGroup("wheel")) {
              return polkit.Result.YES;
            }
          });
        '';
      };
    };
}
