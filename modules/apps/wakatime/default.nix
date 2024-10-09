{ config, lib, ... }:
let
  cfg = config.myApps.wakatime;
in
{
  options.myApps.wakatime = {
    enable = lib.mkEnableOption "wakatime" // {
      default = true;
    };
    wakapi = {
      apiKeyPath = lib.mkOption {
        type = lib.types.str;
        description = "Path to file containing wakapi api key";
      };
      url = lib.mkOption {
        type = lib.types.str;
        description = "Base URL of wakapi instance, including proto.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      WAKATIME_HOME = "${config.xdg.configHome}/wakatime";
    };

    xdg.configFile = {
      "wakatime/.wakatime.cfg" = {
        text = ''
          [settings]
          debug = false
          metrics = false
          guess_language = false
          offline = true

          api_key_vault_cmd = cat ${cfg.wakapi.apiKeyPath}
          api_url = ${cfg.wakapi.url}/api

          hide_file_names = false
          hide_project_names = false
          hide_branch_names = false
          hide_project_folder = false
          include_only_with_project_file = false
          exclude_unknown_project = false

          status_bar_enabled = true
          status_bar_coding_activity = true
        '';
      };
    };
  };
}
