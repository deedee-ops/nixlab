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
      "thunderai@micz.it" = {
        install_url = "https://services.addons.thunderbird.net/thunderbird/downloads/latest/thunderai/addon-988699-latest.xpi";
        installation_mode = "force_installed";
      };
      "accountcolors@gazhay" = {
        install_url = "https://github.com/Vigilans/accountcolors/releases/latest/download/accountcolors.zip";
        installation_mode = "force_installed";
      };
    };
  };
in
{
  options.myHomeApps.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
    impermanenceMethod = lib.mkOption {
      type = lib.types.enum [
        "symlink"
        "bindfs"
      ];
      default = if (config.programs.thunderbird.profiles == { }) then "symlink" else "bindfs";
      description = ''
        Each impermanence mode has is upsides and downsides.
        bindfs  - Sometimes it crashes, and leaves persisted and current directory diverged.
                  To mitigate that, custom thunderbird wrapper is configured, to remount it each time.
        symlink - Way more reliable, but you can't use profiles managed by nix, as
                  home-manager will try to create symlink in persist directory, and will complain
                  it's outside of $HOME.
      '';
    };
  };

  config =
    let
      patchPackage = osConfig.mySystem.impermanence.enable && cfg.impermanenceMethod == "bindfs";
      basePackage = pkgs.thunderbird-latest.override (old: {
        extraPolicies = (old.extraPolicies or { }) // policies;
      });
      package =
        if patchPackage then
          pkgs.writeShellScriptBin "thunderbird" ''
            # ensure bindfs is there
            systemctl --user start bindMount-persist-home-${osConfig.mySystem.primaryUser}-thunderbird.service
            exec ${lib.getExe basePackage} "$@"
          ''
        else
          basePackage;
    in
    lib.mkIf cfg.enable {
      programs.thunderbird = {
        inherit package;

        enable = true;
        # workaround to disable profile management by nix
        profiles = { };
      };

      home = {
        packages = [
          package
        ]
        ++ lib.optionals patchPackage [
          (pkgs.makeDesktopItem {
            name = "thunderbird";
            desktopName = "Thunderbird";
            exec = lib.getExe package;
            icon = "thunderbird";
          })
        ];

        persistence."${osConfig.mySystem.impermanence.persistPath}${config.home.homeDirectory}".directories =
          lib.mkIf osConfig.mySystem.impermanence.enable [
            {
              directory = ".thunderbird";
              method = cfg.impermanenceMethod;
            }
          ];
      };

      myHomeApps.awesome = {
        autorun = [ (lib.getExe package) ];
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
