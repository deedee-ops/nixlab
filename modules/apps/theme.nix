{ config, lib, ... }:
let
  cfg = config.myHomeApps.theme;
in
{
  options.myHomeApps.theme = lib.mkOption {
    type = lib.types.submodule {
      options = {
        terminalFontSize = lib.mkOption {
          type = lib.types.int;
          description = "Size of terminal font";
          default = 12;
        };
      };
    };
    default = { };
  };
  config = {
    stylix = {
      enable = true;
      autoEnable = false;
      fonts.sizes.terminal = cfg.terminalFontSize;
    };
  };
}
