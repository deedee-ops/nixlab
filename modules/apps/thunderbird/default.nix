{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.thunderbird;
in
{
  options.myHomeApps.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
    desktopNumber = lib.mkOption {
      type = lib.types.int;
      description = "Virtual desktop number.";
      default = 7;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird-latest.overrideAttrs (attr: {
        buildCommand = attr.buildCommand + ''
          wrapProgram "$executablePath" \
            --set 'HOME' '${config.xdg.configHome}'
        '';
      });

      # workaround to disable profile management by nix
      profiles = { };
    };

    home = {
      activation = {
        thunderbird = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${config.xdg.configHome}/thunderbird || true
        '';
      };
      packages = [
        config.programs.thunderbird.package # for quicklaunch entry
      ];
      file = {
        ".config/.thunderbird".source =
          config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/thunderbird";
        ".mozilla/native-messaging-hosts".enable = lib.mkForce false;
      };
    };

    myHomeApps.awesome = {
      autorun = [ (lib.getExe config.programs.thunderbird.package) ];
      awfulRules = [
        {
          rule = {
            class = "thunderbird";
          };
          properties = {
            screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
            tag = " ${builtins.toString cfg.desktopNumber} ";
          };
        }
      ];
      floatingClients.role = [
        "AlarmWindow"
        "ConfigManager"
      ];
    };
  };
}
