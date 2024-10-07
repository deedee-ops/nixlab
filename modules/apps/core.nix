{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.myApps = {
    appendHome = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra custom options which will be merged with config.home.";
    };
    shellInitScriptFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "Extra script paths invoked on shell initialization.";
      default = [ ];
    };
    shellInitScriptContents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Extra script bodies invoked on shell initialization.";
      default = [ ];
    };
  };

  config = {
    nix.settings.use-xdg-base-directories = true;

    home = {
      activation = {
        dirs = ''
          run mkdir -p ${config.home.homeDirectory}/Downloads || true
          run mkdir -p ${config.home.homeDirectory}/Pictures/Screenshots || true
          run mkdir -p ${config.home.homeDirectory}/Projects || true
        '';
      };

      keyboard = {
        layout = "pl";
        options = [ "caps:escape" ];
      };

      packages = [
        pkgs.bzip2
        pkgs.dnsutils
        pkgs.jq
        pkgs.pwgen
        pkgs.silver-searcher
      ];
    } // config.myApps.appendHome;
  };
}
