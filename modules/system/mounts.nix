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
        };
      }
    );
    default = [ ];
  };

  config =
    let
      withNFS = (lib.lists.findFirstIndex (mount: mount.type == "nfs") null cfg.mounts) != null;
    in
    {
      environment.systemPackages = lib.optionals withNFS [ pkgs.nfs-utils ];
      services.rpcbind.enable = withNFS;

      systemd.mounts = builtins.map (
        mount:
        if (mount.type == "nfs") then
          {
            type = "nfs";
            what = mount.src;
            where = mount.dest;
            mountConfig = {
              Options = "noatime";
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
