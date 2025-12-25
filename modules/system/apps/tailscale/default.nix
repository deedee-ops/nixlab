{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.tailscale;
  dataDir = "/var/lib/tailscale";
in
{
  options.mySystemApps.tailscale = {
    enable = lib.mkEnableOption "tailscale";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    enableUI = lib.mkEnableOption "tailscale client UI";
    autoProvision = lib.mkEnableOption ''
      Auto provision with auth key. To so:
      - login to tailscale
      - Add device => Linux server
      - (if you wish to provision multiple machines, set auth key as reusable)
      - Generate install script
      - Put auth key in sops secret
      - Deploy tailscale config to machines
      - When machines appears in tailscale UI:
        - ... => Disable key expiry
        - ... => Edit route settings...
          - Enable all Subnet routes
    '';
    authKeySopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing auth key.";
      default = "system/apps/tailscale/auth-key";
    };
    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of CIDRs to be advertised inside tailnet.";
      default = [ ];
      example = [ "192.168.0.0/16" ];
    };
    customServer = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Custom tailscale server, or null for propertiary one.";
      example = "headscale.example.com";
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for tailscale are disabled!") ];

    sops.secrets = lib.optionalAttrs cfg.autoProvision { "${cfg.authKeySopsSecret}" = { }; };

    home-manager.users."${config.mySystem.primaryUser}" = {
      home.shellAliases = {
        tailscale-up = "${lib.getExe config.services.tailscale.package} up --accept-routes --operator=${config.mySystem.primaryUser}";
      };
      systemd.user.services.tail-tray = lib.mkIf cfg.enableUI {
        Unit = {
          Description = "tail-tray";
          Requires = [ "tray.target" ];
          After = [
            "graphical-session.target"
            "tray.target"
          ];
          PartOf = "graphical-session.target";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = lib.getExe pkgs.tail-tray;
          Environment = [
            "PATH=${lib.makeBinPath [ config.services.tailscale.package ]}"
          ];
          Restart = "on-failure";
          RestartSec = 3;
        };
      };
    };

    services = {
      tailscale = {
        enable = true;
        disableTaildrop = true;
      }
      // lib.optionalAttrs cfg.autoProvision {
        authKeyFile = config.sops.secrets."${cfg.authKeySopsSecret}".path;
        extraUpFlags = [
          "--accept-dns=false"
          "--accept-routes"
        ]
        ++ (lib.optionals (builtins.length cfg.advertiseRoutes > 0) [
          ("--advertise-routes=" + (builtins.concatStringsSep "," cfg.advertiseRoutes))
        ])
        ++ [ (lib.optionalString (cfg.customServer != null) "--login-server=https://${cfg.customServer}") ];

      };

      restic.backups = lib.mkIf cfg.backup (
        svc.mkRestic {
          name = "tailscale";
          paths = [ dataDir ];
        }
      );
    };

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ dataDir ]; };
  };
}
