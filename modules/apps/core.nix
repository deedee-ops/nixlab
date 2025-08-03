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
    customURLs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "List of description/url pairs available as desktop shortcuts.";
      example = {
        "Homelab" = "https://homelab.example.com/";
      };
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to install.";
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
      type = lib.types.lines;
      description = "Extra script bodies invoked on shell initialization.";
      default = "";
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

    xdg.dataFile = lib.mapAttrs' (name: value: {
      name = "applications/${name}.desktop";
      value.text = ''
        [Desktop Entry]
        Encoding=UTF-8
        Name=${name}
        Type=Link
        URL=${value}
        Icon=text-html
      '';
    }) config.myHomeApps.customURLs;
  };
}
