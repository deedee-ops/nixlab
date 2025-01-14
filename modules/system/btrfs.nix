{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.mySystem.filesystem == "btrfs") {
    services.btrfs.autoScrub = {
      enable = true;
      fileSystems =
        if config.mySystem.impermanence.enable then
          (builtins.attrNames config.mySystem.disks.systemDatasets)
          ++ [ config.mySystem.impermanence.persistPath ]
        else
          [ "/" ];
    };
  };
}
