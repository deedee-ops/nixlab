{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.thunderbird;
  policies = {
    ExtensionSettings = {
      "*".installation_mode = "blocked"; # blocks all addons except the ones specified below

      "owl@beonex.com" = {
        # Owl for Exchange
        install_url = "https://addons.thunderbird.net/thunderbird/downloads/latest/owl-for-exchange/latest.xpi";
        installation_mode = "force_installed";
      };
      "tbkeys@addons.thunderbird.net" = {
        # tbkeys
        install_url = "https://github.com/wshanks/tbkeys/releases/latest/download/tbkeys.xpi";
        installation_mode = "force_installed";
      };
      "quickmove@mozilla.kewis.ch" = {
        # Quick folder move
        install_url = "https://addons.thunderbird.net/thunderbird/downloads/latest/quick-folder-move/latest.xpi";
        installation_mode = "force_installed";
      };
      "{f6d05f0c-39a8-5c4d-96dd-4852202a8244}" = {
        # catppuccin mocha-blue
        install_url = "https://raw.githubusercontent.com/catppuccin/thunderbird/main/themes/mocha/mocha-blue.xpi";
        installation_mode = "force_installed";
      };
    };
  };
in
{
  options.myHomeApps.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
  };

  config =
    let
      package = pkgs.thunderbird-128.override (old: {
        extraPolicies = (old.extraPolicies or { }) // policies;
      });

    in
    lib.mkIf cfg.enable {
      programs.thunderbird = {
        inherit package;

        enable = true;
        profiles.default.isDefault = true;
      };

      home.persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
        lib.mkIf osConfig.mySystem.impermanence.enable [ ".thunderbird" ];

      myHomeApps.awesome = {
        autorun = [ (lib.getExe package) ];
        awfulRules = [
          {
            rule = {
              class = "thunderbird";
            };
            properties = {
              screen = if config.myHomeApps.awesome.singleScreen then 1 else 2;
              tag = " 5 ";
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
