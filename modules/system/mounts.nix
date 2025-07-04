{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem;
in
{
  options.mySystem.mounts = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          type = lib.mkOption {
            type = lib.types.enum [ "nfs" ];
            description = "Type of mount.";
          };
          src = lib.mkOption {
            type = lib.types.str;
            description = "Mount source.";
          };
          dest = lib.mkOption {
            type = lib.types.str;
            description = "Mount desctination.";
          };
          opts = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Extra mount options";
            example = "ro";
            default = null;
          };
        };
      }
    );
    default = [ ];
  };

  config =
    let
      withNFS =
        (lib.lists.findFirstIndex (mount: mount.type == "nfs") null cfg.mounts) != null
        || config.mySystemApps.nfs.enable;
    in
    {
      environment.systemPackages = lib.optionals withNFS [ pkgs.nfs-utils ];
      services.rpcbind.enable = withNFS;
      boot.kernelModules = lib.optionals withNFS [ "nfs" ];

      systemd.mounts = builtins.map (
        mount:
        if (mount.type == "nfs") then
          {
            type = "nfs";
            what = mount.src;
            where = mount.dest;
            mountConfig = {
              Options = "noatime" + (lib.optionalString (mount.opts != null) ",${mount.opts}");
            };
          }
        else
          { }
      ) cfg.mounts;

      systemd.automounts = builtins.map (mount: {
        where = mount.dest;
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
      }) cfg.mounts;
    };
}
