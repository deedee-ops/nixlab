{
  config,
  lib,
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
    autoProvision = lib.mkEnableOption "auto provision with auth key";
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
  };

  config = lib.mkIf cfg.enable {
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for tailscale are disabled!") ];

    sops.secrets."${cfg.authKeySopsSecret}" = { };

    services = {
      tailscale =
        {
          enable = true;
          disableTaildrop = true;
        }
        // lib.optionalAttrs cfg.autoProvision {
          authKeyFile = config.sops.secrets."${cfg.authKeySopsSecret}".path;
          extraUpFlags =
            [
              "--accept-dns=false"
            ]
            ++ (lib.optionals (builtins.length cfg.advertiseRoutes > 0) [
              ("--advertise-routes=" + (builtins.concatStringsSep "," cfg.advertiseRoutes))
            ]);

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
