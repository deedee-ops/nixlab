{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.xorg.autorandr;
in
{
  options.myHomeApps.xorg.autorandr = {
    profile = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
    };
  };

  config = lib.mkIf (osConfig.mySystem.xorg.enable && cfg.profile != null) {
    programs.autorandr = {
      enable = true;
      profiles = {
        default = cfg.profile;
      };
    };

    services.autorandr.enable = true;

    xsession = {
      profileExtra = ''
        ${lib.getExe pkgs.autorandr} --load default
      '';
    };
  };
}
