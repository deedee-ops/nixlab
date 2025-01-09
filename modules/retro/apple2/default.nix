{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.myRetro) core;

  cfg = config.myRetro.apple2;
in
{
  imports = [
    ./linapple
  ];

  options.myRetro.apple2 = {
    enable = lib.mkEnableOption "Apple II" // {
      default = config.myRetro.retrom.enable;
    };
    package = lib.mkOption {
      type = lib.types.package;
      description = "Package of Apple II emulator.";
      default = pkgs.callPackage ../../pkgs/linapple.nix { };
    };
    saveStatePath = lib.mkOption {
      type = lib.types.path;
      description = "Path to save states directory.";
      default = "${core.savesDir}/${cfg.package.pname}";
    };
  };
}
