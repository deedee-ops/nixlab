{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:

{
  options.myHomeApps = {
    allowUnfree = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of allowed unfree packages.";
      default = [ ];
    };
    appendHome = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra custom options which will be merged with config.home.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Exrtra packages to install.";
    };
    openPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      description = "List of additionally opened ports on system.";
      default = [ ];
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

    home = lib.attrsets.recursiveUpdate {
      preferXdgDirectories = true;

      keyboard = {
        layout = "pl";
        options = [ "caps:escape" ];
      };

      packages = [
        pkgs.bzip2
        pkgs.dnsutils
        pkgs.file
        pkgs.jq
        pkgs.lsof
        pkgs.nh
        pkgs.pwgen
        pkgs.silver-searcher
      ] ++ config.myHomeApps.extraPackages;

      persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}" =
        lib.mkIf osConfig.mySystem.impermanence.enable
          {
            allowOther = true;
            directories = [
              ".cache"
              ".local"
              "Downloads"
              "Pictures"
              "Projects"
            ];
          };
    } config.myHomeApps.appendHome;
  };
}
