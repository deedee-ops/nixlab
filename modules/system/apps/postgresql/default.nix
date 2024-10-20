{ config, lib, ... }:
let
  cfg = config.mySystemApps.postgresql;
in
{
  options.mySystemApps.postgresql = {
    enable = lib.mkEnableOption "postgresql";
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      identMap = ''
        # ArbitraryMapName systemUser DBUser
         superuser_map      root      postgres
         superuser_map      postgres  postgres

         # Let other names login as themselves
         superuser_map      /^(.*)$   \1
      '';
      authentication = ''
        #type database  DBuser  auth-method optional_ident_map
        local sameuser  all     peer        map=superuser_map
      '';
    };

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
