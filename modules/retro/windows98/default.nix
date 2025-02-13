{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.myRetro) core;

  cfg = config.myRetro.windows98;
in
{
  imports = [
    ./86box
  ];

  options.myRetro.windows98 = {
    enable = lib.mkEnableOption "windows98" // {
      default = config.myRetro.retrom.enable;
    };
    package = lib.mkOption {
      type = lib.types.package;
      description = "Package of windows98 emulator.";
      default = pkgs._86Box.override { unfreeEnableRoms = true; };
    };
    saveStatePath = lib.mkOption {
      type = lib.types.path;
      description = "Path to save states directory.";
      default = "${core.savesDir}/${cfg.package.pname}";
    };
  };
}
