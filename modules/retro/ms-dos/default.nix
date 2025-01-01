{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.myRetro) core;

  cfg = config.myRetro.ms-dos;
in
{
  imports = [
    ./dosbox-x
  ];

  options.myRetro.ms-dos = {
    enable = lib.mkEnableOption "MS-DOS" // {
      default = config.myRetro.retrom.enable;
    };
    package = lib.mkOption {
      type = lib.types.package;
      description = "Package of MS-DOS emulator.";
      default = pkgs.dosbox-x;
    };
    saveStatePath = lib.mkOption {
      type = lib.types.path;
      description = "Path to save states directory.";
      default = "${core.savesDir}/${cfg.package.pname}";
    };
  };
}
