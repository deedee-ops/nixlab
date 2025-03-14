{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.myRetro) core;

  cfg = config.myRetro.nintendo64;
in
{
  imports = [
    ./simple64
  ];

  options.myRetro.nintendo64 = {
    enable = lib.mkEnableOption "Nintendo 64" // {
      default = config.myRetro.retrom.enable;
    };
    package = lib.mkOption {
      type = lib.types.package;
      description = "Package of Nintendo 64 emulator.";
      default = pkgs.simple64;
    };
    saveStatePath = lib.mkOption {
      type = lib.types.path;
      description = "Path to save states directory.";
      default = "${core.savesDir}/${cfg.package.pname}";
    };
  };
}
