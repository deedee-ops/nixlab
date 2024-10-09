{ config, lib, ... }:
let
  cfg = config.mySystemApps.postgresql;
in
{
  options.mySystemApps.postgresql = {
    enable = lib.mkEnableOption "postgresql";
  };

  config = lib.mkIf cfg.enable {
    services.postgresql.enable = true;

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              directory = config.services.postgresql.dataDir;
              user = "postgres";
              group = "postgres";
              mode = "750";
            }
          ];
        };
  };
}
