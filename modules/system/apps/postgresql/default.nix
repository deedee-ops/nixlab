{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.postgresql;
in
{
  options.mySystemApps.postgresql = {
    enable = lib.mkEnableOption "postgresql";
    backup = lib.mkEnableOption "postgresql backup" // {
      default = true;
    };
    enablePgVectoRs = lib.mkOption {
      type = lib.types.bool;
      description = "Enable pg-vecto.rs extension.";
      default = false;
      example = true;
    };
    initSQL = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Per-database list of init SQL scripts, where key is databases name.";
      example = {
        immich = "CREATE EXTENSION IF NOT EXISTS vectors;";
      };
      default = { };
    };
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
    warnings = [ (lib.mkIf (!cfg.backup) "WARNING: Backups for postgresql are disabled!") ];

    services =
      let
        backupPath = "/var/lib/postgresql/backups";
      in
      {
        postgresql =
          {
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
            ensureDatabases = lib.flatten (builtins.map (opt: opt.databases) cfg.userDatabases);
            ensureUsers = builtins.map (opt: { name = opt.username; }) cfg.userDatabases;

            settings = {
              password_encryption = "scram-sha-256";
            };
          }
          // lib.optionalAttrs cfg.enablePgVectoRs {
            extraPlugins = ps: [ ps.pgvecto-rs ];
            settings = {
              shared_preload_libraries = [ "vectors.so" ];
              search_path = "\"$user\", public, vectors";
            };
          };

        postgresqlBackup = lib.mkIf cfg.backup {
          enable = true;
          location = backupPath;
          startAt = "*-*-* 01:00:00";
        };

        restic.backups = lib.mkIf cfg.backup (
          svc.mkRestic {
            name = "postgresql";
            paths = [ backupPath ];
          }
        );
      };

    users.users.postgres.extraGroups = [ "abc" ];

    systemd.services.postgresql.postStart =
      ''
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
      ''
      + builtins.concatStringsSep "\n" (
        builtins.map (db: ''
          $PSQL -d ${db} -f "${(pkgs.writeText "init-${db}.sql" (builtins.getAttr db cfg.initSQL))}"
        '') (builtins.attrNames cfg.initSQL)
      );

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        {
          directories = [
            {
              directory = "/var/lib/postgresql";
              user = "postgres";
              group = "postgres";
              mode = "750";
            }
          ];
        };
  };
}
