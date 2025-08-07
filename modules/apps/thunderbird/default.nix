{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.thunderbird;
  policies = {
    # to get name, check `applications.gecko.id` in manifest.json
    ExtensionSettings = {
      "*".installation_mode = "blocked"; # blocks all addons except the ones specified below

      "owl@beonex.com" = {
        # Owl for Exchange
        install_url = "https://www.beonex.com/owl/owl.xpi";
        installation_mode = "force_installed";
      };
      "tbkeys@addons.thunderbird.net" = {
        # tbkeys
        # renovate: datasource=github-releases depName=wshanks/tbkeys
        install_url = "https://github.com/wshanks/tbkeys/releases/download/v2.4.1/tbkeys.xpi";
        installation_mode = "force_installed";
      };
      "quickmove@mozilla.kewis.ch" = {
        # Quick folder move
        # renovate: datasource=github-releases depName=kewisch/quickmove-extension
        install_url = "https://addons.thunderbird.net/thunderbird/downloads/file/1038431/quick_folder_move-3.3.0-tb.xpi";
        installation_mode = "force_installed";
      };
      "{f6d05f0c-39a8-5c4d-96dd-4852202a8244}" = {
        # catppuccin mocha-blue
        install_url = "https://raw.githubusercontent.com/catppuccin/thunderbird/main/themes/mocha/mocha-blue.xpi";
        installation_mode = "force_installed";
      };
      "thunderai@micz.it" = {
        # renovate: datasource=github-releases depName=micz/ThunderAI
        install_url = "https://addons.thunderbird.net/thunderbird/downloads/file/1040072/thunderai_chatgpt_gemini_ollama_in_your_emails-3.6.0-tb.xpi";
        installation_mode = "force_installed";
      };
      "accountcolors@gazhay" = {
        # renovate: datasource=github-releases depName=Vigilans/accountcolors
        install_url = "https://github.com/Vigilans/accountcolors/releases/download/tb-140/accountcolors.zip";
        installation_mode = "force_installed";
      };
    };
  };
in
{
  options.myHomeApps.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
  };

  config = lib.mkIf cfg.enable {
    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird-latest.override (old: {
        extraPolicies = (old.extraPolicies or { }) // policies;
      });

      # workaround to disable profile management by nix
      profiles = { };
    };

    home = {
      packages = [ config.programs.thunderbird.package ];
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
            tag = if config.myHomeApps.whatsie.enable then " 5 " else " 6 ";
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
