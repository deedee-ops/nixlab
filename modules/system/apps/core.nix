{
  inputs,
  config,
  lib,
  ...
}:

{
  options.mySystemApps = {
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      description = "Per machine list of extra packages";
      default = [ ];
    };
  };

  config = {
    environment.systemPackages = [
      inputs.ghostty.packages.x86_64-linux.default.terminfo
    ] ++ config.mySystemApps.extraPackages;
  };
}
