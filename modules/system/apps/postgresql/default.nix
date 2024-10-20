{ config, lib, ... }:
let
  cfg = config.mySystemApps.postgresql;
in
{
  options.mySystemApps.postgresql = {
    enable = lib.mkEnableOption "postgresql";
    userDatabases = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            username = lib.mkOption { type = lib.types.str; };
            passwordFile = lib.mkOption { type = lib.types.str; };
            databases = lib.mkOption { type = lib.types.listOf lib.types.str; };
          };
        }
      );
      description = "Map of users and their corresponding databases including password file.";
      example = [
        {
          username = "user";
          passwordFile = "/path/to/password-file";
          databases = [
            "user"
            "other"
          ];
        }
      ];
    };
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
        #type database  DBuser  host-mask     auth-method   optional_ident_map
        local sameuser  all                   peer          map=superuser_map
        host  sameuser  all     ${config.mySystemApps.docker.network.private.subnet} scram-sha-256
      '';
      enableTCPIP = true;
      settings = {
        password_encryption = "scram-sha-256";
      };
    };

    services.postgresql = {
      ensureDatabases = lib.flatten (builtins.map (opt: opt.databases) cfg.userDatabases);
      ensureUsers = builtins.map (opt: { name = opt.username; }) cfg.userDatabases;
    };

    users.users.postgres.extraGroups = [ "abc" ];

    systemd.services.postgresql.postStart = ''
      $PSQL -tA <<'EOF'
        DO $$
        DECLARE password TEXT;
        BEGIN
        ${
          builtins.concatStringsSep "\n" (
            builtins.map (opt: ''
              password := trim(both from replace(pg_read_file('${opt.passwordFile}'), E'\n', '''));
              EXECUTE format('ALTER ROLE ${opt.username} WITH PASSWORD '''%s''';', password);
              ${builtins.concatStringsSep "\n" (
                builtins.map (db: ''
                  ALTER DATABASE "${db}" OWNER TO "${opt.username}";
                '') opt.databases
              )}
            '') cfg.userDatabases
          )
        }
        END $$;
      EOF
    '';

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
