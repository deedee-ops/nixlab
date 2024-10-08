{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.homepage;
in
{
  options.mySystemApps.homepage = {
    enable = lib.mkEnableOption "homepage dashboard";
    groups = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Group name.";
            };
            layout = lib.mkOption {
              type = lib.types.enum [
                "row"
                "column"
              ];
              default = "column";
              description = "Group elements layout.";
            };
            columns = lib.mkOption {
              type = lib.types.int;
              default = 4;
              description = "Only when layout=row. Sets number of columns per row.";
            };
          };
        }
      );
      default = [ ];
    };
    services = lib.mkOption {
      type = lib.types.attrs;
      description = "Normalized (set of sets of sets, without lists) services config.";
      default = { };
      example = {
        Group = {
          Service1 = {
            description = "my service";
          };
          Service2 = {
            href = "localhost";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;

      services = builtins.map (
        key:
        (builtins.map (innerKey: (builtins.getAttr innerKey (builtins.getAttr key cfg.services))) (
          builtins.attrNames (builtins.getAttr key cfg.services)
        ))
      ) (builtins.attrNames cfg.services);

      settings = {
        title = "DeeDee";
        startUrl = "https://www.${config.mySystem.rootDomain}/";
        theme = "dark";
        headerStyle = "clean";
        baseUrl = "https://www.${config.mySystem.rootDomain}/";
        target = "_blank";
        hideVersion = true;
        useEqualHeights = true;
        layout = builtins.listToAttrs (
          builtins.map (group: {
            inherit (group) name;

            value = {
              style = group.layout;
            } // (lib.optionalAttrs (group.layout == "row") { inherit (group) columns; });
          }) cfg.groups
        );
      };

      widgets = {
        datetime = {
          text_size = "x1";
          format = {
            dateStyle = "medium";
            timeStyle = "medium";
            hour12 = false;
            timeZone = config.mySystem.timezone;
          };
        };
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          cputemp = "true";
          tempmin = 0;
          tempmax = 100;
          uptime = true;
          units = "metric";
          diskUnits = "bytes";
        };
      };
    };

    services.nginx.virtualHosts.homepage =
      (svc.mkNginxVHost "www" "http://localhost:${builtins.toString config.services.homepage-dashboard.listenPort}")
      // {
        default = true;
      };
  };
}
