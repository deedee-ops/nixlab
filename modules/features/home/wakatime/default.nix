_: {
  flake.homeModules.features-home-wakatime =
    { config, lib, ... }:
    {
      config = {
        sops.secrets = lib.genAttrs [ "wakatime/apiKey" ] (_: {
          sopsFile = ./secrets.sops.yaml;
        });

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

              api_key_vault_cmd = cat ${config.sops.secrets."wakatime/apiKey".path}
              api_url = https://wakapi.ajgon.casa/api

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
    };
}
