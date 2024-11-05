{ config, lib, ... }:
let
  cfg = config.myHomeApps.wakatime;
in
{
  options.myHomeApps.wakatime = {
    enable = lib.mkEnableOption "wakatime" // {
      default = true;
    };
    wakapi = {
      apiKeySopsSecret = lib.mkOption {
        type = lib.types.str;
        description = "Sops secret name containing wakapi API key.";
        default = "home/apps/wakapi/api_key";
      };
      url = lib.mkOption {
        type = lib.types.str;
        description = "Base URL of wakapi instance, including proto.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.wakapi.apiKeySopsSecret}" = { };

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

          api_key_vault_cmd = cat ${config.sops.secrets."${cfg.wakapi.apiKeySopsSecret}".path}
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
